-- ZeDUI/tools/qa/vk2_mouse.lua  (Nov 22 2026, QA KISS batch K2; tag vk2_mse): the in-game proof of Build's fixes for
-- K2-2, K2-3, K2-6, K2-7 and K2-8, the mouse and keyboard half of the batch (the findings: ZeDUI/qa/audits/
-- 2026-11-22_kiss_fixes_K2.md). Build's commits: 194d5dd2a (K2-3, K2-7, K2-8) and da6134ec4 (K2-2, K2-6). The old
-- code for every item is 0ebd56570; the fix is da6134ec4. Built on rt_kit.lua (the global RT), run after
-- zedqa_prelude.lua. grep "ZEDQA vk2_mse". Manifest (QA's): vk2_mouse.lua | vk2_mse | timeout=360
--
-- The findings, as the player meets them:
--   K2-2  he clicks the belt's hand holding the crowbar to put it away and nothing happens (the pad's A on it does).
--   K2-3  he pins a recipe to keep it at the top; under Show: Ready it drops out whenever he cannot make it right now.
--   K2-6  Escape over ZeD's map opens the game's pause menu instead of closing the map.
--   K2-7  the card offers Use on wipes, thread and the other drainables the game's double-click ignores, and Use does
--         nothing; a bandage dragged onto a body part or a wound row of the Health tab does nothing.
--   K2-8  a double-click on Nails (50) in a crate takes one nail.
--
-- What each check reads, and what the old code (0ebd56570) does. Every check below FAILS there and PASSES on the fix:
--   K2-6 (World window, Maps tab). ZeD's map opened by its unfold button (a press where a click lands: the drawer's
--     onMouseDown, MapsTab.onClick), drawn; then Escape handed to the game's key handler (ToggleEscapeMenu, the function
--     the game's OnKeyPressed event runs: ZeD's key hook first, then the game's own pause toggle). 300 ms later:
--     * the map is closed (the World window holds no pop-out, the pop-out is gone from the UI roots), the game's pause
--       menu is shut (MainScreen not visible) and the game is not paused. Old code: no Escape taker for the map: the map
--       stays open, the pause menu opens and the game pauses (the run shuts the pause menu at once by the same toggle).
--     An observation, not a check (a NOTE line): the map opened again with the note tool in hand, words typed in its
--     note box (setText, the box focused), Escape: whether the map closes and where the words go (Build: they are
--     lost). The run cannot press a real key, so whether the game hands a real Escape to a focused box first is not
--     seen here.
--   K2-3 (World window, Crafting tab). Show: All, every category, no search, no card, no station (each set back after).
--     The recipe: one the list holds that he knows and has the skill for but cannot make now (status missing, else
--     unlocked), not pinned and not one of the most used; the first by name. Its row brought into view and
--     right-clicked (the drawer's onRightMouseDown, CraftingTab.onRightClick: the pin toggle); then Show: Ready
--     (CraftingCore.setShow, what the band's Show list sets), the list filtered again, the row brought into view (the
--     list stamps a zone for every row it holds, drawn or not).
--     * the pinned recipe is listed under Show: Ready: in the filtered list, in the Pinned group, its row drawn in the
--       list's view, its status still not craftable. Old code: Ready leaves it out (no Pinned group, no row).
--   K2-8 (World window, Loot). A crate beside him (carpentry_01_16) with 50 nails, shown as a list (not a grid), the
--     nails' stack shut, the World window on it. Two clicks a frame apart at the middle of the Nails (50) row (the
--     list's own onMouseDown and onMouseUp). Timed actions instant for this part only (the fifty moves are quick; the
--     cheat as found right after). No room in his inventory for the nails (the game's own hasRoomFor, the test its
--     transfer asks) is a SKIP.
--     * once the queue is empty, all 50 of the script's nails are in his inventory and none in the crate. Old code:
--       quickUse moved { item }: one nail comes, 49 stay.
--   K2-2 (the belt). A crowbar given (a two-hand weapon: the game equips it in both hands); his hands emptied for the
--     part (put back after). The crowbar's row dragged from his list onto the belt's main hand (press, move and release
--     by the list's own handlers; handleDrop asks the belt, ZeD.Belt.takeDrop, the game's equip), then a left click on
--     that hand (the belt's own onMouseDown and onMouseUp at the hand's middle, one frame: the belt drops a press the
--     real button does not hold).
--     * the click queues the game's put-away for the crowbar (ISUnequipAction), read at once. Old code: onMouseUp does
--       nothing for a hand: nothing is queued.
--     * once the queue is empty the crowbar is in neither hand and in his inventory; with the drag staged, the drag must
--       also have drawn it into the hand (the drag still equips; a drag that cannot be staged here is a SKIP line, and
--       the game's setter puts the crowbar in his hand for the click). Old code: it stays in his hands.
--     A belt hand under a window on this screen (a real click lands on the window), at the drag or at the click, is a
--     SKIP.
--   K2-7 (cards). Painkillers, alcohol wipes, thread and a lighter given, their stacks opened; each card opened by a
--     click on its row (a card that covers the whole list on a small screen is shut by its own X first); the verbs the
--     card drew (card._lastHeaderVerbs) and its model's (card._model.verbs) read.
--     * three checks, no Use on the card of the wipes, the thread, the lighter: no USE drawn or in the model, while the
--       painkillers' card, read the same way, shows Use (the game's double-click takes a pill: the reading is not
--       empty). Old code: every drainable's card has Use.
--   K2-7 (drops on the Health tab). God mode off for this part only (with it the game heals a wound at once),
--     invincible on, a guard every tick (no infection; health under 80, or two minutes: the part is healed and god mode
--     put on). A scratch with infection off on the first arm part with no wound and no bandage (the left forearm
--     first). The Health tab open, its figure unfolded, at its top. Two bandages: in his inventory when his list shows
--     beside the tab, else on the ground at his feet, in the World window's floor list. Each is dragged by the list's
--     own handlers and let go with the pointer on a point the drop's own tests take (on the figure its hitTestAt names
--     the part; inside the tab's view, under its header, above its band, left of its bar; not under the World window
--     or the belt).
--     * dropped on the part on the figure: right after the drop the queue holds the game's health panel route
--       (HealthPanelAction with HApplyBandage on that part), or within 2 s ISApplyBandage on that part; the queue is
--       cleared the moment it is seen (nothing is bandaged, no bandage used). Old code: handleDrop has no Health tab
--       answer: nothing is queued.
--     * the same, dropped on the part's wound row (the tab scrolled until the row is in view; a point of the row off the
--       figure).
--   The put-back checks at the end PASS on the old code too: they say the run left him as it found him.
--
-- The pointer is the one thing faked: the game reads the real pointer, so for each press, move and release the global
-- getMouseX / getMouseY answer the point for that call only, and every ZeD list and strip answers "not over me" to its
-- Java isMouseOver (bx_inventory.lua's way). ZeD's input mode is locked to the mouse for the run (vx12_wheel.lua's
-- lock and its put-back): every path here is the mouse's or the keyboard's. Waits go by the clock; nothing in pixels is
-- written in (points come from the zones ZeD stamps), so it runs as it is at 4K (UI scale 1.75) and 1280x800 (Auto).
-- Every press, drop and click point is tested against the other ZeD window and the belt drawn over it: a point a real
-- press could not reach on this screen makes that check a SKIP, said plainly (K2-2's hand, K2-3's row, a K2-7 drop's
-- point); a drag or click that cannot be made is a FAIL.
-- Run offline before the first game run (Nov 22 2026: KRun, the real rt_kit.lua and this script in the game's Kahlua
-- against a stubbed game and a MODEL of the ZeD paths it drives, written from 0ebd56570 and da6134ec4, not the shipped
-- files; the harness is not in the repo): the old model FAILs the 10 fix checks and PASSes the load and put-back
-- checks; the new model PASSes all 17; the same at 4K, with the pair found shut, his list hidden beside the Health tab
-- (the bandages from the ground's list), ZeD found reading the pad, and the clock leaping to the put-back at five points
-- (only "finished in time" FAILs; every put-back check PASSes). Parse-checked with the game's compiler (KCheck).
--
-- What it puts back (also when a step throws or the time runs out): the queue cleared, every drag let go, the map
-- closed, the pause menu shut, the game speed, the map's note tool; the wound healed, god mode, invincible and instant
-- actions as found, the guard off; everything given or made taken away (inventory, ground, crate), the crate removed,
-- his hands as found; the Crafting tab's pins (its list and the save's copy), Show, Sort, category, folds, search,
-- open card and scroll, a bound station bound again; the lists' grid choices (his inventory, the crate, the ground),
-- stacks, group folds, picks, view and scroll, the columns, the cards the run opened (shut by their own X); both
-- windows' tabs, open or shut, places and sizes (by their own setters only if the tab presses did not bring them
-- back), their roll-up timers; the input lock and the mode ZeD reads. No option is changed or saved, no file is
-- written, ZEDQA_LAYOUT_BACK is never called.

if not (RT and RT.make) then
    print("ZEDQA vk2_mse ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vk2_mse VERDICT FAIL 1")
    print("ZEDQA vk2_mse DONE")
    return
end

local Q = RT.make("vk2_mse")
Q.maxMs = 240000   -- (four minutes, then the put-back; a run takes about one)
local S = { p = RT.p, pn = RT.pn, was = {}, made = {}, stacks = {}, seek = {}, grid = {}, folds = {}, b2 = {}, c3 = {}, m6 = {},
    u7 = {}, d7 = { drops = {} }, n8 = {} }
local H = {}   -- shared helpers
local B = {}   -- K2-2, the belt
local C = {}   -- K2-3, the Crafting tab
local M = {}   -- K2-6, the map
local U = {}   -- K2-7, the cards' Use
local D = {}   -- K2-7, the drops on the Health tab
local N = {}   -- K2-8, the nails
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
    if it == nil then return "nothing" end   -- (under -debug a nil indexed inside pcall still logs a Java exception)
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
function H.sameList(a, b)
    a, b = a or {}, b or {}
    if #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end
function H.list(t) local out = {}; for _, v in ipairs(t or {}) do out[#out + 1] = tostring(v) end; return table.concat(out, ", ") end

-- ===================================================================== things
function H.main() return S.p:getInventory() end
-- the container a thing is really in: its link, when that container's own list holds it
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
-- given to his inventory (the kit takes it back at the end too)
function H.give(ft)
    local it = RT.give(ft)
    if it then S.made[#S.made + 1] = it end
    return it
end
function H.addFloor(sq, ft, ox, oy)
    local it = nil
    if sq then pcall(function() it = sq:AddWorldInventoryItem(ft, ox, oy, 0) end) end
    return H.track(it)
end
-- on the ground: its ground object still on a square
function H.onFloor(it)
    local on = false
    pcall(function()
        local wo = it:getWorldItem()
        local sq = wo and wo:getSquare()
        on = sq ~= nil and sq:getWorldObjects():contains(wo)
    end)
    return on and true or false
end
-- a thing off the character and out of the world, wherever it is (vx10_tab.lua X.removeItem)
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
-- his hands as found (only what is still his)
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
-- until cond() holds (asked every frame), at most ms; then fn(ok). Every poll holds the windows down.
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
-- at least minMs, then until cond() holds, at most maxMs; then fn(ok)
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
-- a window not where it was found, set back by its own setters (never ZEDQA_LAYOUT_BACK); true when it moved it
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
-- the windows at rest: the same places and sizes for 300 ms (a drawer slides over a few frames)
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
-- the windows held down for the run: the roll-up timers in the future (as bxr_win.lua and vx10_tab.lua hold them) and
-- a window rolled up to its title bar brought down (the found state goes back at the end)
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
-- an item card the run opened, shut by its own X (the card's onBackClick: the picks let go, the drawer updated, a tab
-- under it left open). Also the drawer a drag left in item mode with no card: a drag's press opens the card, its move
-- hides it, and the drawer stays open for it until the list's picks are updated.
function H.shutCard(k)
    local w = H.win(k)
    local card = w and w._itemCard
    if w and (w._drawerItem ~= nil or w._drawerMode == "item") and card and card.onBackClick then pcall(card.onBackClick) end
end
-- a container's list shown as a list, not a grid, for the run (its grid choice as found kept once, put back at the end)
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
-- the window on tab id by its strip's own press (RT.goTab: no press when it is there); the window's own opener when
-- the strip has no such tab drawn
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
-- the viewed and the active container (by their inventories) and the list's own inventory (vx10_tab.lua X.viewOf)
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
-- the Character list put on view v (vx10_tab.lua X.viewTo); nothing moves when it is there already
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
-- (asked step by step, so a missing list or scroll gives nil without a throw)
function H.scrollBar(k) local c = H.content(k); return c and c._scroll or nil end
function H.scrollOf(k) local sc, s = H.scrollBar(k), nil; if sc then pcall(function() s = sc.scrollPos end) end; return s end
function H.scrollTo(k, pos) local sc = H.scrollBar(k); if pos ~= nil and sc then pcall(function() sc:setScrollPos(pos) end) end end
-- a stack of the list opened (open true) or shut; the state found kept once, put back at the end
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
-- sorted by category, a folded group hides its rows: every fold of the list opened for the run (vx10_food.lua), folded
-- again at the end
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
-- the row drawn last frame stands whole in the list's view and a click at its middle lands on it (vx10_food.lua): the
-- heading's and the buttons' zones come first, so the middle of a row half under the heading would press them
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
-- (a condition, every frame: the row shown whole last frame, else the list one step further down; wraps at the end;
-- a step is at most half a view, so every row stands whole at one of them)
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
-- getMouseX / getMouseY answer (gx, gy) for fn's call only (ZeD's handlers and ISUIElement:getMouseX look the globals up
-- at call time; zedqa_pagelist_lib.lua S.wheelAt)
function H.atPointer(gx, gy, fn)
    local ox, oy = getMouseX, getMouseY
    getMouseX = function() return gx end
    getMouseY = function() return gy end
    local ok, err = pcall(fn)
    getMouseX, getMouseY = ox, oy
    return ok, err
end
-- every ZeD list and container strip answers "the pointer is not over me" for fn's call (their Java isMouseOver reads
-- the real pointer; bx_inventory.lua H.over)
function H.notOver(fn)
    local saved = {}
    local no = function() return false end
    for _, k in ipairs({ "c", "w" }) do
        local w = H.win(k)
        if w then
            for _, o in ipairs({ w._mainContent or false, w._containerStrip or false }) do
                if o then
                    saved[#saved + 1] = { o, rawget(o, "isMouseOver") }
                    o.isMouseOver = no
                end
            end
        end
    end
    local ok, err = pcall(fn)
    for i = #saved, 1, -1 do saved[i][1].isMouseOver = saved[i][2] end
    return ok, err
end
-- el's place among the UI roots (drawn in order: a later root is drawn over it), nil when it is not one
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
-- is the screen point under the other ZeD window or the belt, drawn over owner? (a real press there lands on that)
function H.covered(owner, gx, gy)
    local oi = H.zIndex(owner)
    if not oi then return false end
    for _, c in ipairs({ RT.cw() or false, RT.ww() or false, B.hud() or false }) do
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
-- the window a list belongs to
function H.ownerOf(c)
    if c ~= nil and c == H.content("c") then return RT.cw() end
    if c ~= nil and c == H.content("w") then return RT.ww() end
    return nil
end
-- a left click on a row: down and up at its middle, the pointer there; never the second of a double-click
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
-- a drag the way the list's own handlers take one, all in one frame (a drag held over frames would be dropped: the real
-- button is not down): the press at the row's middle, a move 40 px off it (past the drag threshold: the drag starts and
-- hides the card), the release with the pointer at (gx, gy) and every list and strip answering "not over me"
function H.drag(src, item, gx, gy)
    local z = H.rowZone(src, item)
    if not (src and z) then return false, "the row is not on screen" end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    local ax, ay = src:getAbsoluteX() + x, src:getAbsoluteY() + y
    local cov, by = H.covered(H.ownerOf(src), ax, ay)
    if cov then return false, "the row's middle is under the " .. tostring(by) end
    src._zedLastClick = nil
    local ok, err = H.atPointer(ax, ay, function() src:onMouseDown(x, y) end)
    if not ok then return false, "the press threw: " .. tostring(err) end
    local d = src._drag
    if not (d and d:isPending()) then return false, "the press began no drag" end
    ok, err = H.atPointer(ax + 40, ay + 40, function() src:onMouseMove(40, 40) end)
    if not (ok and d:isActive()) then
        pcall(function() d:cancel() end)
        pcall(function() src:setCapture(false) end)
        return false, "the move did not start the drag" .. (ok and "" or (": " .. tostring(err)))
    end
    local lx, ly = gx - src:getAbsoluteX(), gy - src:getAbsoluteY()
    local okR, errR = true, nil
    H.atPointer(gx, gy, function()
        okR, errR = H.notOver(function() src:onMouseUpOutside(lx, ly) end)
    end)
    if not okR then return false, "the release threw: " .. tostring(errR) end
    return true, "pressed at " .. H.num(ax) .. "," .. H.num(ay) .. ", let go at " .. H.num(gx) .. "," .. H.num(gy)
end
-- every drag still in the air let go (bx_inventory.lua H.cancelDrags)
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

-- ===================================================================== the input mode ZeD reads (vx12_wheel.lua)
-- the lock as found: ZeD setup's Input lock, as Settings.lua applies it at load ("auto" is no lock); the save's
-- modData copy only when the setting cannot be read
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
-- a mode locked ("kbm": the mouse); nil or false puts back the lock found (only a lock this script set)
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
-- the lock lifted and, with no lock found, the mode ZeD read: the detector's tick copied the lock into its own mode and
-- only real input switches it, so a moment's lock on the mode found lets the tick take it (H.modeFree lifts it)
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

-- ===================================================================== K2-2: the belt
function B.hud() local h = nil; pcall(function() h = ZeD.Belt.getHUD(S.pn) end); return h end
function B.drawn() local hud = B.hud(); return hud ~= nil and hud._drawn == true end
function B.hand(which)
    local hud = B.hud()
    for _, b in ipairs((hud and hud._boxes) or {}) do
        if b.kind == "hand" and b.which == which then return b, hud end
    end
    return nil, hud
end
-- the hand's middle: in the belt's own pixels and on screen
function B.center(b, hud)
    local lx, ly = b.x + math.floor(b.w / 2), b.y + math.floor(b.h / 2)
    return lx, ly, hud:getAbsoluteX() + lx, hud:getAbsoluteY() + ly
end
function B.unequipFor(item)
    for _, a in ipairs(H.queue()) do
        if type(a) == "table" and a.Type == "ISUnequipAction" and a.item == item then return a end
    end
    return nil
end

-- ===================================================================== K2-3: the Crafting tab (vx11_craft.lua's helpers)
function C.st() local w = RT.ww(); return w and w._craftState end
function C.data() local w = RT.ww(); return w and w._craftCache end
function C.geo() local st = C.st(); return st and st._listGeo end
function C.row(name) local d = C.data(); if not (d and d.byName and name) then return nil end; return d.byName[name] end
function C.showing() local s = false; pcall(function() s = ZeD_WorldWindow.isTabShowing("craft", S.pn) end); return s and true or false end
function C.zone(name)
    local st = C.st()
    for _, z in ipairs((st and st.zones) or {}) do
        if z.type == "recipeRow" and z.id == name and z.w > 0 and z.h > 0 then return z end
    end
    return nil
end
function C.inView(z)
    local g = C.geo()
    return g ~= nil and z ~= nil and z.y >= g.viewY and z.y + z.h <= g.viewY + g.viewH
end
function C.listed(name)
    local st = C.st()
    for _, rd in ipairs((st and st.filteredCache) or {}) do if rd.entry and rd.entry.name == name then return true end end
    return false
end
-- the list's Pinned group holds it (and whether that group is folded)
function C.inPinned(name)
    local st = C.st()
    for _, sec in ipairs((st and st._sections) or {}) do
        if sec.id == "pinned" then
            for _, rd in ipairs(sec.items or {}) do
                if rd.entry and rd.entry.name == name then return true, sec.collapsed and true or false end
            end
        end
    end
    return false, false
end
function C.rowH() local h = 24; pcall(function() h = ZeD.T.px(ZeD.CraftingCore.ROW_H) end); return h end
-- the row's offset from the list view's top (px), its zone, the list's geometry and the offset the list draws from
function C.rel(name)
    local st, g, z = C.st(), C.geo(), C.zone(name)
    if not (st and g and z and st.scroll) then return nil end
    local off = math.floor((st.scroll.scrollPos or 0) * math.max(0, (g.totalH or 0) - (g.viewH or 0)))
    return z.y - g.viewY, z, g, off
end
-- the list scrolled so the row sits relT px under the view's top (as far as the list's ends allow)
function C.place(name, relT)
    local st = C.st()
    local rel, _, g, off = C.rel(name)
    if not (rel and st.scroll.setScrollPos) then return false end
    local span = (g.totalH or 0) - (g.viewH or 0)
    if span <= 0 then return true end
    local want = rel + off - relT
    if want < 0 then want = 0 end
    if want > span then want = span end
    st.scroll:setScrollPos((want + 0.5) / span)
    return true
end
function C.mid()
    local g = C.geo()
    if not g then return 0 end
    return math.max(0, math.floor((g.viewH - C.rowH()) / 2))
end
function C.keepState(st)
    return { show = st.show, showAll = st.showAll, sort = st.sort, cat = st.activeCat, req = st.reqCollapsed, out = st.outCollapsed,
        all = st.allCollapsed, pin = st.pinnedCollapsed, freq = st.freqCollapsed, owned = st.ownedOnly, search = st.search or "",
        sel = st.selected, picks = st.picks, qty = st.qty, scroll = (st.scroll and st.scroll.scrollPos) or 0, alt = st.altSlotName }
end
-- the search: the field and the tab's state set together (the field's own poll then sees no change)
function C.setSearch(st, text)
    local w = RT.ww()
    local f = w and w._craftSearch or nil
    if f and f.input then
        pcall(function() f.input:setText(text) end)
        f._lastText = text
    end
    st.search, st.filterDirty = text, true
end
function C.shut()
    local st = C.st()
    if not st then return end
    if st.altSlotName then pcall(ZeD.CraftingCore.exitAltMode, st) end
    if st.selected then pcall(ZeD.CraftingCore.closeCraft, st) end
end
function C.pins() local w = RT.ww(); return (w and w._craftPins) or {} end
function C.isPinned(name) for _, n in ipairs(C.pins()) do if n == name then return true end end; return false end
-- the recipe: listed now, known (no learning wanted, or learned), the skill there, not craftable now (missing, else
-- unlocked), not pinned, no card open on it, not among the most used; the first by name
function C.pick()
    local d, st = C.data(), C.st()
    if not (d and st) then return nil end
    local listed = {}
    for _, rd in ipairs(st.filteredCache or {}) do listed[rd] = true end
    local freq = st._freqCounts or {}
    local best = {}
    for _, rd in ipairs(d.recipes or {}) do
        local e = rd.entry
        if e and listed[rd] and (rd.status == "missing" or rd.status == "unlocked") and rd.hasSkill
            and ((not e.needLearn) or rd.learned) and not C.isPinned(e.name) and e.name ~= st.selected and not freq[e.name] then
            local cur = best[rd.status]
            if cur == nil or tostring(e.displayName) < tostring(cur.entry.displayName) then best[rd.status] = rd end
        end
    end
    return best.missing or best.unlocked
end
-- the pins as found: the save's copy exactly, the window's list from it (or as found when the tab had loaded them)
function C.pinsBack()
    local T3 = S.c3
    if not T3.pinsTaken then return end
    pcall(function()
        local md = S.p:getModData()
        if T3.mdPinsHad then md.ZeD_CraftPins = H.copy(T3.mdPinsWas) else md.ZeD_CraftPins = nil end
    end)
    local w = RT.ww()
    if w then
        if T3.pinsWas ~= nil then w._craftPins = H.copy(T3.pinsWas)
        else
            local l = {}
            for _, n in ipairs(T3.mdPinsWas or {}) do l[#l + 1] = n end
            w._craftPins = l
        end
    end
    local st = C.st()
    if st and w then
        st.pins = w._craftPins
        st.filterDirty, st._sectionsStale = true, true
    end
end
-- the tab's choices as found (the list is filtered again the next frame it draws)
function C.stateBack()
    local T3 = S.c3
    local st, k = C.st(), T3.keep
    if not (st and k and T3.seen) then return end
    pcall(function()
        st.show, st.showAll, st.sort, st.activeCat = k.show, k.showAll, k.sort, k.cat
        st.reqCollapsed, st.outCollapsed, st.allCollapsed = k.req and true or false, k.out and true or false, k.all and true or false
        st.pinnedCollapsed, st.freqCollapsed, st.ownedOnly = k.pin and true or false, k.freq and true or false, k.owned and true or false
        st.qty, st.filterDirty, st._sectionsStale = k.qty or 1, true, true
        st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen, st.stDropdownOpen = false, false, false, false
        if T3.searchWas then C.setSearch(st, k.search or "") end
    end)
end
-- the card that was open, its picks and amount, and the list's scroll
function C.cardBack()
    local T3 = S.c3
    local st, k = C.st(), T3.keep
    if not (st and k and T3.seen) then return end
    pcall(function() if k.sel and st.selected ~= k.sel then ZeD.CraftingCore.openCraft(st, k.sel) end end)
    pcall(function() st.picks = k.picks or {}; st.qty = k.qty or 1 end)
    pcall(function() st.scroll:setScrollPos(k.scroll or 0) end)
end
function C.stationBack()
    local T3 = S.c3
    if T3.stWas and not T3.stBack then
        T3.stBack = true
        pcall(function() ZeD.Stations.bind(S.p, T3.stWas) end)
    end
end

-- ===================================================================== K2-6: the map
function M.pop() local w = RT.ww(); return w and w._mapPopout end
-- ZeD's map up and drawn: visible, among the UI roots, raised on its first drawn frame
function M.popUp()
    local pop = M.pop()
    if not pop then return false end
    local v = false
    pcall(function() v = pop:isReallyVisible() end)
    return v and pop._raiseOnce == nil and H.inUI(pop)
end
function M.pauseUp()
    local ms = MainScreen and MainScreen.instance
    local v = false
    if ms then pcall(function() v = ms:isVisible() end) end
    return v and true or false
end
-- Escape as the game hands it on: ToggleEscapeMenu, what its OnKeyPressed event runs (ZeD's key hook, the game's)
function M.escape() return pcall(function() ToggleEscapeMenu(Keyboard.KEY_ESCAPE) end) end
-- the pause menu shut by the game's own toggle (the player's pause key)
function M.unpause()
    if not M.pauseUp() then return end
    pcall(function()
        local key = nil
        if KeybindId and KeybindId.MAIN_MENU then key = getCore():getKey(KeybindId.MAIN_MENU) end
        if key == nil or key == 0 then key = Keyboard.KEY_ESCAPE end
        ToggleEscapeMenu(key)
    end)
end
-- the unfold button pressed where a click lands (the World window's drawer: MapsTab.onClick)
function M.unfold()
    local w = RT.ww()
    local z = w and w._mapPopoutZone
    local d = w and w._drawerPanel
    if not (z and d) then return false, "no unfold button drawn" end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    local ok, err = H.atPointer(d:getAbsoluteX() + x, d:getAbsoluteY() + y, function() d:onMouseDown(x, y) end)
    if not ok then return false, "the press threw: " .. tostring(err) end
    return true, "pressed"
end
function M.closeIfOpen()
    local w = RT.ww()
    if w and w._mapPopout then pcall(ZeD.MapsTab.closePopout, w, true) end
end
function M.putBack()
    local T6 = S.m6
    if T6.te then pcall(function() T6.te:unfocus() end) end
    M.unpause()
    M.closeIfOpen()
    local w = RT.ww()
    if w and T6.toolTaken then w._mapActiveTool, w._mapEdit = T6.toolWas, T6.editWas end
    local sp = S.was.speed
    if sp ~= nil and getGameSpeed() ~= sp then
        if ZEDQA_SPEED then pcall(ZEDQA_SPEED, sp) else pcall(setGameSpeed, sp) end
    end
end

-- ===================================================================== K2-7: the cards' Use
U.KINDS = {
    { key = "pills", ft = "Base.Pills", word = "painkillers" },
    { key = "wipes", ft = "Base.AlcoholWipes", word = "alcohol wipes" },
    { key = "thread", ft = "Base.Thread", word = "thread" },
    { key = "lighter", ft = "Base.Lighter", word = "a lighter" },
}
function U.card() local w = RT.cw(); return w and w._itemCard end
function U.cardOn(item)
    local w = RT.cw()
    local c = w and w._itemCard
    return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
end
function U.ids(list)
    local out = {}
    for _, v in ipairs(list or {}) do if type(v) == "table" then out[#out + 1] = tostring(v.id) end end
    return table.concat(out, " ")
end
function U.has(list, id)
    for _, v in ipairs(list or {}) do if type(v) == "table" and v.id == id then return true end end
    return false
end
-- the game's double-click on a drainable (vanilla ISInventoryPane:doContextualDblClick): it takes only a consumable
-- that is not a show-poison one (nil when the tags cannot be read)
function U.gameUses(it)
    local r = nil
    pcall(function()
        if not (it and ItemTag and ItemTag.CONSUMABLE and ItemTag.SHOW_POISON) then return end
        r = (instanceof(it, "DrainableComboItem") and it:hasTag(ItemTag.CONSUMABLE) and not it:hasTag(ItemTag.SHOW_POISON)) and true or false
    end)
    return r
end
-- one card: its row found and clicked, the card opened on it, three frames drawn, its verbs read
function U.queueRead(k)
    Q.step(2, function()
        local it = S.u7[k.key]
        k.arm = S.u7.go == true and it ~= nil
        S.seek.c = nil
        if not it then k.why = "it could not be given" end
        if not k.arm then return end
        -- (a card over the whole list, on a small screen: shut by its own X, so the next row can be clicked)
        local c = H.content("c")
        local vis = false
        if c then pcall(function() vis = c:isReallyVisible() and c:getWidth() > 0 end) end
        if not vis then H.shutCard("c") end
    end)
    H.wait(8000, function() return not k.arm or H.seekRow("c", S.u7[k.key]) end, function(ok)
        if not k.arm then return end
        if not ok then k.arm = false; k.why = "its row is not on view in his list"; return end
        local okC, err = H.click("c", S.u7[k.key])
        if not okC then k.arm = false; k.why = "the click on its row failed: " .. tostring(err) end
    end)
    H.wait(4000, function()
        if not k.arm then return true end
        local it = S.u7[k.key]
        local c = U.card()
        return U.cardOn(it) and c._model ~= nil and c._model.item == it and c._lastHeaderVerbs ~= nil
    end, function(ok)
        if not k.arm then return end
        if not ok then
            k.arm = false
            local w = RT.cw()
            k.why = "its card did not open on it (the card shows " .. H.nm(w and w._drawerItem) .. ")"
        end
    end)
    Q.step(3, function()
        if not k.arm then return end
        local c = U.card()
        local it = S.u7[k.key]
        if not (U.cardOn(it) and c._model and c._model.item == it) then k.why = "its card closed before it was read"; return end
        k.drawn, k.model = U.ids(c._lastHeaderVerbs), U.ids(c._model.verbs)
        k.useDrawn = U.has(c._lastHeaderVerbs, "USE")
        k.useModel = U.has(c._model.verbs, "USE")
        k.game = U.gameUses(it)
        k.read = true
    end)
end
function U.text(k)
    if not k.read then return k.word .. "'s card not read (" .. tostring(k.why) .. ")" end
    return k.word .. "'s card drew [" .. tostring(k.drawn) .. "], its model [" .. tostring(k.model) .. "]; the game's double-click "
        .. ((k.game == true) and "uses it" or ((k.game == false) and "does nothing with it" or "(tags not read)"))
end

-- ===================================================================== K2-7: the drops on the Health tab
-- the arm parts tried in turn (the figure's name is the wound row's too for these)
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
function D.bp() return S.d7.part and D.bpOf(S.d7.part.t) or nil end
-- the first arm part with no wound and no bandage
function D.pickPart()
    for _, e in ipairs(D.PARTS) do
        local b = D.bpOf(e.t)
        local clean = false
        if b then pcall(function() clean = not b:HasInjury() and not b:bandaged() and not b:stitched() end) end
        if clean then return e end
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
    return w ~= nil and w._drawerMode == "tab" and w._activeTab == "health" and (w._drawerEffW or 0) > 0 and vis
end
function D.rowZone()
    local w = RT.cw()
    local name = S.d7.part and S.d7.part.name
    for _, z in ipairs((w and w._healthInjuryZones) or {}) do if z.bodyPartName == name then return z end end
    return nil
end
-- a point (the tab's own pixels) where a drop is taken: in the tab's view, under its pinned header, above its band,
-- left of its bar, inside the panel, not under the World window or the belt. True and the screen point, or false.
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
    -- (the screen point the tab's own getMouseX reads back as lx: ISUIElement takes off the panel's own scroll too)
    local xs, ys = 0, 0
    local jo = p.javaObject
    if jo then pcall(function() xs, ys = jo:getXScroll(), jo:getYScroll() end) end
    local gx, gy = p:getAbsoluteX() + xs + lx, p:getAbsoluteY() + ys + ly
    if H.covered(w, gx, gy) then return false end
    return true, gx, gy
end
-- a point of the part on the figure: its rect's middle first, then a 5 by 5 grid over it; the figure's own hit test
-- must name the part there
function D.figurePoint()
    local fig, w = D.fig(), RT.cw()
    local name = S.d7.part and S.d7.part.name
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
    return nil, "no point of the " .. tostring(name) .. " is in the tab's view and uncovered"
end
-- a point of the part's wound row, off the figure (the drop asks the figure first)
function D.rowPoint()
    local z = D.rowZone()
    if not z then return nil, "no wound row for the " .. tostring(S.d7.part and S.d7.part.name) end
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
-- (a condition, every frame: the wound row in view, else the tab one step further down; wraps at the end)
function D.seekRowView()
    if D.rowPoint() then return true end
    local w = RT.cw()
    local sc = w and w._healthScroll
    if sc and sc.visible and sc.setScrollPos then
        local at = S.d7.seek
        if at == nil or at >= 1 then at = 0 else at = math.min(1, at + 0.1) end
        S.d7.seek = at
        pcall(function() sc:setScrollPos(at) end)
    end
    return false
end
-- the game's health panel route on the part (HealthPanelAction carrying HApplyBandage), and its bandage action
function D.routeFor(bp)
    if bp == nil then return nil end
    for _, a in ipairs(H.queue()) do
        local hd = (type(a) == "table") and a.handler or nil
        if type(hd) == "table" and a.Type == "HealthPanelAction" and hd.Type == "HApplyBandage" and hd.bodyPart == bp then return a end
    end
    return nil
end
function D.applyFor(bp)
    if bp == nil then return nil end
    for _, a in ipairs(H.queue()) do
        if type(a) == "table" and a.Type == "ISApplyBandage" and a.bodyPart == bp and a.doIt then return a end
    end
    return nil
end
function D.noInfection()
    local b = D.bp()
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
-- the scratch, infection off (setScratched's second argument: no infection), as bx_health.lua stages one
function D.wound()
    local b = D.bp()
    if not b then return false end
    pcall(function() b:setScratched(true, true) end)
    pcall(function() b:setScratchTime(15) end)
    D.noInfection()
    local s = false
    pcall(function() s = b:scratched() end)
    return s and true or false
end
-- the part made whole: the scratch, any bleeding and any bandage of the run off, infection off, its health back
function D.heal()
    local b = D.bp()
    if b then
        pcall(function() b:setScratched(false, true) end)
        pcall(function() b:setScratchTime(0) end)
        pcall(function() b:setBleeding(false) end)
        pcall(function() b:setBleedingTime(0) end)
        pcall(function() if b:bandaged() then b:setBandaged(false, 0) end end)
        pcall(function() b:setAdditionalPain(0) end)
        pcall(function() b:RestoreToFullHealth() end)
    end
    D.noInfection()
end
-- the guard, every game tick while god mode is off for the wound: no infection; health under 80 or two minutes and
-- the part is healed and god mode put on (the game then heals the rest)
function D.guard()
    local T = S.d7
    if not T.guardOn then pcall(function() Events.OnTick.Remove(D.guard) end); return end
    D.noInfection()
    local h, dead = 100, false
    pcall(function() h = S.p:getBodyDamage():getOverallBodyHealth() end)
    pcall(function() dead = S.p:isDead() end)
    if dead or h < 80 or getTimestampMs() - (T.guardT0 or 0) > 120000 then
        T.tripped = dead and "dead" or ("health " .. H.num(h) .. " after " .. H.num((getTimestampMs() - (T.guardT0 or 0)) / 1000) .. " s")
        D.heal()
        pcall(function() S.p:setGodMod(true) end)
        T.guardOn = false
        pcall(function() Events.OnTick.Remove(D.guard) end)
    end
end
-- the drawer at one width for 10 polls (it slides open over a few frames)
function D.still()
    local w = RT.cw()
    local e = math.floor((w and w._drawerEffW) or 0)
    if e == S.d7.lastW then S.d7.same = (S.d7.same or 0) + 1 else S.d7.same, S.d7.lastW = 0, e end
    return S.d7.same >= 10
end
function D.putBack()
    local T = S.d7
    if T.backDone or not T.staged then return end
    T.backDone = true
    H.clearQueue()
    D.heal()
    T.guardOn = false
    pcall(function() Events.OnTick.Remove(D.guard) end)
    pcall(function() S.p:setInvincible(S.was.inv and true or false) end)
    pcall(function() S.p:setGodMod(S.was.god and true or false) end)
    if T.instSet then pcall(function() S.p:setTimedActionInstantCheat(S.was.inst and true or false) end) end
    local w = RT.cw()
    if w then
        if T.foldWas ~= nil then w._healthFigureExpanded = T.foldWas end
        if T.scrollWas ~= nil and w._healthScroll then pcall(function() w._healthScroll:setScrollPos(T.scrollWas) end) end
    end
    for _, it in ipairs(T.band or {}) do pcall(H.removeItem, it) end
end
-- one drop of bandage i on the point ptFn() gives: the drag, then the queue read at once and every frame for 2 s;
-- T.drops[i]. preWhy: a staging reason found before (the rows not on view), nil when none. A point the tab cannot
-- offer on this screen (out of its view, under the World window or the belt) is a SKIP, said plainly; a drop that
-- cannot be made is a FAIL.
function D.queueDrop(i, label, ptFn, preWhy)
    Q.step(2, function()
        local T = S.d7
        if not T.go then return end
        local r = { label = label }
        T.drops[i] = r
        local pre = preWhy and preWhy() or nil
        if pre then r.why = pre; return end
        local pt, why = ptFn()
        if not pt then r.skip = why; return end
        local okD, how = H.drag(H.content(T.src), T.band[i], pt.gx, pt.gy)
        r.how = how
        if not okD then r.why = how; return end
        r.go = true
        r.route = D.routeFor(D.bp())
        r.q0 = H.queueText()
        r.t0 = getTimestampMs()
    end)
    H.wait(2000, function()
        local r = S.d7.drops[i]
        if not (r and r.go) then return true end
        r.route = r.route or D.routeFor(D.bp())
        r.apply = D.applyFor(D.bp())
        return r.apply ~= nil
    end, function()
        local T = S.d7
        local r = T.drops[i]
        if not (T.go and r) then return end
        -- (cancelled the moment it was seen: nothing is bandaged, no bandage used)
        if r.go then
            r.q1 = H.queueText()
            H.clearQueue()
        end
        local b = D.bp()
        local band = false
        if b then pcall(function() band = b:bandaged() end) end
        if band then r.bandaged = true; pcall(function() b:setBandaged(false, 0) end) end
        -- (the drawer the drag's press opened for the bandage's card in the source's window, shut by the card's X)
        if T.src and S.card0 and S.card0[T.src] == nil then H.shutCard(T.src) end
        local what = "K2-7: a bandage dragged from " .. T.srcName .. " and dropped on " .. label
            .. " starts the game's bandage action on that part (old code: the drop does nothing)"
        if r.skip then Q.skip(what, tostring(r.skip)); return end
        local item = r.apply and r.apply.item
        Q.check(r.go == true and (r.route ~= nil or r.apply ~= nil), what,
            (r.go and (tostring(r.how) .. "; right after the drop the queue held [" .. tostring(r.q0) .. "] (the health panel's route on the "
                .. T.part.name .. ": " .. tostring(r.route ~= nil) .. "), then [" .. tostring(r.q1) .. "] (ISApplyBandage on the "
                .. T.part.name .. ": " .. tostring(r.apply ~= nil) .. (item and (", with " .. H.nm(item)) or "") .. "), cleared at once")
                or ("not dropped: " .. tostring(r.why)))
            .. (r.bandaged and "; the part was found bandaged after the cancel: the bandage taken off" or ""))
    end)
end

-- ===================================================================== K2-8: the nails
function N.wc() return H.content("w") end
-- a square beside him: loaded, free, nothing else on it, in reach
function N.freeSq()
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
-- a crate (bx_inventory.lua H.mkCrate)
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
function N.count(inv)
    local n = 0
    for _, it in ipairs(S.n8.list or {}) do if H.where(it) == inv then n = n + 1 end end
    return n
end
-- the nails' row in the World window's list: the zone whose thing is one of the script's nails
function N.rowZone()
    local wc = N.wc()
    for _, z in ipairs((wc and wc._hitZones) or {}) do
        if type(z.id) ~= "string" and S.n8.set and S.n8.set[z.id] then return z end
    end
    return nil
end
-- the moves of the script's nails in the queue
function N.moves()
    local n = 0
    for _, a in ipairs(H.queue()) do
        if type(a) == "table" and a.item ~= nil and S.n8.set and S.n8.set[a.item] then n = n + 1 end
    end
    return n
end
function N.putBack()
    local T8 = S.n8
    if T8.backDone then return end
    T8.backDone = true
    if T8.instSet then pcall(function() S.p:setTimedActionInstantCheat(S.was.inst and true or false) end); T8.instSet = false end
    for _, it in ipairs(T8.list or {}) do pcall(H.removeItem, it) end
    if T8.crate then N.rmCrate(T8.crate) end
    local ww = RT.ww()
    if ww then ww._containerTimer = 30 end
end

-- ===================================================================== start: what was found
Q.step(3, function()
    local dead = true
    pcall(function() dead = S.p:isDead() end)
    if dead then S.dead = true; Q.check(false, "the character is alive (nothing is run on a dead one)"); return end
    local ready = ZeD ~= nil and ZeD.Belt ~= nil and ZeD.Belt.getHUD ~= nil and ZeD.CraftingCore ~= nil and ZeD.CraftingTab ~= nil
        and ZeD.MapsTab ~= nil and ZeD.MapsTab.closePopout ~= nil and ZeD.HealthTab ~= nil and ZeD.InventoryRenderer ~= nil
        and ZeD_CharacterWindow ~= nil and ZeD_WorldWindow ~= nil and ISTimedActionQueue ~= nil and ToggleEscapeMenu ~= nil
        and S.Det ~= nil and S.Det.setLockedMode ~= nil and S.Det.getMode ~= nil
    if not Q.check(ready, "ZeD's belt, Crafting tab, map, Health tab, lists, the game's key handler and the input lock are loaded") then
        S.dead = true
        return
    end
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "vk2_mse") end
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
    pcall(function() S.was.inst = S.p:isTimedActionInstantCheat() and true or false end)
    pcall(function() S.was.health = S.p:getBodyDamage():getOverallBodyHealth() end)
    S.was.pause = M.pauseUp()
    S.was.mode = H.mode()
    S.lockWas = H.lockFound()
    H.clearQueue()
    H.lock("kbm")
    H.openBoth()
    Q.say("start: screen " .. RT.core:getScreenWidth() .. "x" .. RT.core:getScreenHeight() .. ", ZeD's scale " .. tostring(ZeD.T and ZeD.T.scale)
        .. "; Character window open " .. tostring(S.was.char) .. " (" .. H.gs(S.was.geo.c) .. ", on " .. tostring(S.was.tab.c) .. "), World window open "
        .. tostring(S.was.world) .. " (" .. H.gs(S.was.geo.w) .. ", on " .. tostring(S.was.tab.w) .. "); game speed " .. H.num(S.was.speed)
        .. "; god mode " .. tostring(S.was.god) .. ", invincible " .. tostring(S.was.inv) .. ", instant actions " .. tostring(S.was.inst)
        .. ", health " .. H.num(S.was.health) .. "; Input lock " .. tostring(S.lockWas) .. ", ZeD reads " .. tostring(S.was.mode)
        .. "; in his hands " .. H.nm(S.was.hand.p) .. " / " .. H.nm(S.was.hand.s))
end)
H.wait(6000, function() return S.dead or H.both() end, function(ok)
    if S.dead then return end
    if not ok then
        S.dead = true
        Q.check(false, "the scene: both windows open", "Character " .. tostring(H.charOpen()) .. ", World " .. tostring(H.worldOpen()))
        return
    end
    local cw, ww = RT.cw(), RT.ww()
    S.outWas = { c = cw._outSince, w = ww._outSince }
    S.was.shaded = { c = cw.windowShaded and true or false, w = ww.windowShaded and true or false }
    S.was.rolled = { c = cw._rolled and true or false, w = ww._rolled and true or false }
    -- (a side rolled away under its tab comes down for the run, and is rolled again at the end)
    local CU = ZeD.Curtain
    if cw._rolled and CU and CU.finishUnroll then pcall(CU.finishUnroll, cw) end
    if ww._rolled and CU and CU.finishUnroll then pcall(CU.finishUnroll, ww) end
    H.hold()
    -- extra columns shut for the run (opened again at the end)
    S.cols = { c = H.colsOf(cw), w = H.colsOf(ww) }
    if #S.cols.c > 0 then pcall(ZeD_CharacterWindow.closeColumns, cw) end
    if #S.cols.w > 0 then pcall(ZeD_WorldWindow.closeColumns, ww) end
    -- the lists' views and scroll as found; his own inventory on the Character list for the run
    S.view0 = { c = H.viewOf(cw), w = H.viewOf(ww) }
    S.scroll0 = { c = H.scrollOf("c"), w = H.scrollOf("w") }
    S.card0 = { c = cw._drawerItem, w = ww._drawerItem }
    H.viewTo(cw, { aInv = H.main(), cInv = H.main(), mainVis = true })
    -- (his inventory shown as a list for the run: rows, each thing's own once its stack is open; no group folded)
    H.listView(H.main())
    H.unfoldAll("c")
    H.unfoldAll("w")
    S.ready = true
end)

-- ===================================================================== K2-6: Escape on ZeD's map
S.m6.label = "K2-6: Escape with ZeD's map open closes the map, and the game's pause menu stays shut"
Q.step(5, function()
    local T6 = S.m6
    if S.dead then return end
    local ww = RT.ww()
    if not ww then return end
    T6.toolWas, T6.editWas, T6.toolTaken = ww._mapActiveTool, ww._mapEdit, true
    if ww._mapPopout then
        Q.say("NOTE K2-6: ZeD's map was found open: closed for the test (it is not opened again at the end)")
        M.closeIfOpen()
    end
    H.tab("w", "maps")
    T6.go = true
end)
H.wait(8000, function()
    local T6 = S.m6
    if not T6.go then return true end
    local w = RT.ww()
    -- (the windows at rest too: the unfold button's zone is stamped where it was last drawn, so a press made while
    -- the drawer still slides open could miss it)
    return w ~= nil and w._activeTab == "maps" and (w._mapPopoutZone ~= nil or w._mapBlocked == true) and H.settled()
end, function(ok)
    local T6 = S.m6
    if not T6.go then return end
    local w = RT.ww()
    if not (ok and w and w._mapPopoutZone and not w._mapBlocked) then
        T6.go = false
        local why = (not ok) and ("the Maps tab did not show its map (the World window on " .. tostring(w and w._activeTab) .. ")")
            or "the map cannot be read here (too dark, or no world map in this game)"
        Q.skip(T6.label, why)
        return
    end
    local okP, how = M.unfold()
    if not okP then T6.go = false; Q.check(false, "K2-6: the Maps tab's unfold button opens ZeD's map (staging)", how) end
end)
H.wait(5000, function() return not S.m6.go or M.popUp() end, function(ok)
    local T6 = S.m6
    if not T6.go then return end
    if not ok then
        T6.go = false
        Q.check(false, "K2-6: the Maps tab's unfold button opens ZeD's map (staging)", "the World window holds a pop-out " .. tostring(M.pop() ~= nil))
        return
    end
    T6.pop = M.pop()
    T6.speed0 = getGameSpeed()
    T6.okE, T6.errE = M.escape()
    T6.after = { open = M.pop() ~= nil, pause = M.pauseUp() }
end)
Q.waitMs(300)
Q.step(1, function()
    local T6 = S.m6
    if not T6.go then return end
    local w = RT.ww()
    local closed = w ~= nil and w._mapPopout == nil and not H.inUI(T6.pop)
    local pause = M.pauseUp()
    local speed = getGameSpeed()
    -- (the game not paused: running, or at the speed it had before the Escape; the old code's pause menu sets it to 0)
    Q.check(T6.okE and closed and not pause and (speed > 0 or speed == T6.speed0),
        T6.label .. " (old code: the map stays open, the pause menu opens and the game pauses)",
        "Escape through ToggleEscapeMenu ran " .. tostring(T6.okE) .. (T6.okE and "" or (": " .. tostring(T6.errE)))
        .. "; at once: the map open " .. tostring(T6.after.open) .. ", the pause menu up " .. tostring(T6.after.pause)
        .. "; 300 ms on: the World window holds a pop-out " .. tostring(w and w._mapPopout ~= nil) .. ", the pop-out among the UI roots "
        .. tostring(H.inUI(T6.pop)) .. ", the pause menu up " .. tostring(pause) .. ", game speed " .. H.num(speed) .. " (before " .. H.num(T6.speed0) .. ")")
    -- (the old code's pause menu shut again at once by the game's own toggle, and its map closed)
    if pause then M.unpause() end
    if not closed then M.closeIfOpen() end
    T6.typing = closed and not pause
end)
-- an observation, not a check: the map again, the note tool in hand, words typed in its box, Escape
H.wait(4000, function()
    local w = RT.ww()
    return not S.m6.typing or (w ~= nil and w._mapPopout == nil and w._mapPopoutZone ~= nil and not w._mapBlocked)
end, function(ok)
    local T6 = S.m6
    if not T6.typing then return end
    if not ok then T6.typing = false; Q.say("NOTE K2-6 (typing): the unfold button did not come back; not observed"); return end
    local okP = M.unfold()
    if not okP then T6.typing = false; Q.say("NOTE K2-6 (typing): the unfold press failed; not observed") end
end)
H.wait(5000, function() return not S.m6.typing or M.popUp() end, function(ok)
    local T6 = S.m6
    if not T6.typing then return end
    if not ok then T6.typing = false; Q.say("NOTE K2-6 (typing): the map did not open again; not observed"); return end
    T6.pop2 = M.pop()
    local w = RT.ww()
    -- (the note tool in hand: its box shows under the map's toolbar; staging, put back)
    if w then w._mapActiveTool = "text" end
end)
H.wait(3000, function()
    local T6 = S.m6
    if not T6.typing then return true end
    local w = RT.ww()
    local te = w and w._mapTextEntry
    local vis = false
    if te and te ~= w._mapTextEntryInline then pcall(function() vis = te:isReallyVisible() end) end
    return vis
end, function(ok)
    local T6 = S.m6
    if not T6.typing then return end
    local w = RT.ww()
    local te = (ok and w) and w._mapTextEntry or nil
    if not te then
        T6.typing = false
        Q.say("NOTE K2-6 (typing): the map's note box did not show with the note tool in hand; not observed")
        M.closeIfOpen()
        return
    end
    T6.te = te
    T6.words = "ZeDQA unsent words"
    pcall(function() te:setText(T6.words) end)
    pcall(function() te:focus() end)
end)
Q.step(2, function()
    local T6 = S.m6
    if not (T6.typing and T6.te) then return end
    T6.okE2 = M.escape()
end)
Q.waitMs(300)
Q.step(1, function()
    local T6 = S.m6
    if not (T6.typing and T6.te) then return end
    local w = RT.ww()
    local closed = w ~= nil and w._mapPopout == nil and not H.inUI(T6.pop2)
    local pause = M.pauseUp()
    local held, inline = nil, nil
    pcall(function() held = T6.te:getText() end)
    local ie = w and w._mapTextEntry
    if ie and ie ~= T6.te then pcall(function() inline = ie:getText() end) end
    Q.say("NOTE K2-6 (an observation, not a check): words typed in the map's note box (\"" .. T6.words .. "\", the box focused), then Escape (ran "
        .. tostring(T6.okE2) .. "); 300 ms on: the map closed " .. tostring(closed) .. ", the pause menu up " .. tostring(pause) .. "; the box that held the words "
        .. (H.inUI(T6.pop2) and "is still on screen" or "went with the map") .. " (it still reads \"" .. tostring(held) .. "\"), the drawer's own box reads \""
        .. tostring(inline) .. "\": " .. ((closed and inline ~= T6.words) and "the unsent words are lost, as Build's note says" or "see the words above")
        .. ". The run cannot press a real key, so whether the game hands a real Escape to the focused box first is not seen here.")
    pcall(function() T6.te:unfocus() end)
    T6.te = nil
    if pause then M.unpause() end
    M.closeIfOpen()
    if w then w._mapActiveTool, w._mapEdit = T6.toolWas, T6.editWas end
end)

-- ===================================================================== K2-3: a pinned recipe under Show: Ready
S.c3.label = "K2-3: a pinned recipe he cannot make right now stays listed under Show: Ready"
Q.step(5, function()
    local T3 = S.c3
    if S.dead then return end
    local w = RT.ww()
    if not w then return end
    -- (a bound station: unbound for the run, the hand's recipes; bound again after)
    pcall(function()
        local cur = ZeD.Stations and ZeD.Stations.current(S.p)
        if cur then
            T3.stWas = cur
            ZeD.Stations.unbind(S.p)
            Q.say("NOTE K2-3: a station was bound: unbound for the run, bound again after")
        end
    end)
    if w._craftState then T3.keep = C.keepState(w._craftState) end
    -- the pins as found: the window's list and the save's copy
    local md = S.p:getModData()
    T3.pinsWas = H.copy(w._craftPins)
    T3.mdPinsHad = md.ZeD_CraftPins ~= nil
    T3.mdPinsWas = H.copy(md.ZeD_CraftPins)
    T3.pinsTaken = true
    H.tab("w", "craft")
    T3.go = true
end)
H.wait(8000, function()
    local T3 = S.c3
    if not T3.go then return true end
    local st = C.st()
    return C.showing() and st ~= nil and C.data() ~= nil and st.filteredCache ~= nil
end, function(ok)
    local T3 = S.c3
    if not T3.go then return end
    local st = C.st()
    if not (ok and st) then
        T3.go = false
        local w = RT.ww()
        Q.skip(T3.label, "the World window shows no Crafting tab with its list here (on " .. tostring(w and w._activeTab) .. ")")
        return
    end
    T3.seen = true
    T3.keep = T3.keep or C.keepState(st)
    C.shut()
    -- Show: All, every category, the groups unfolded, no search
    pcall(ZeD.CraftingCore.setShow, st, "all")
    st.activeCat, st.allCollapsed, st.pinnedCollapsed, st.freqCollapsed = "all", false, false, false
    st.filterDirty, st._sectionsStale = true, true
    st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen, st.stDropdownOpen = false, false, false, false
    local typed = ""
    local w = RT.ww()
    local f = w and w._craftSearch or nil
    if f then pcall(function() typed = f:getText() or "" end) end
    if typed ~= "" or (st.search or "") ~= "" then
        T3.searchWas = true
        C.setSearch(st, "")
    end
end)
-- (the list filtered again, and two of the game's scans answered for every row: real statuses)
H.settle(2600, 9000, function()
    local st = C.st()
    return not S.c3.go or (st ~= nil and st.filterDirty == false and #(st.filteredCache or {}) > 0)
end, function(ok)
    local T3 = S.c3
    if not T3.go then return end
    local rd = C.pick()
    if not rd then
        T3.go = false
        Q.skip(T3.label, "the list holds no recipe he knows and has the skill for but cannot make now (missing or unlocked), unpinned and not among the most used"
            .. (ok and "" or " (the list did not settle in 9 s)"))
        return
    end
    T3.name, T3.title, T3.status0 = rd.entry.name, tostring(rd.entry.displayName), rd.status
    C.place(T3.name, C.mid())
    Q.say("K2-3: the recipe: " .. T3.title .. " (" .. T3.name .. "), status " .. tostring(rd.status) .. ", learned " .. tostring(rd.learned)
        .. ", has the skill " .. tostring(rd.hasSkill) .. "; his pins: [" .. H.list(C.pins()) .. "]")
end)
H.wait(3000, function()
    local T3 = S.c3
    if not T3.go then return true end
    local z = C.zone(T3.name)
    return z ~= nil and C.inView(z)
end, function(ok)
    local T3 = S.c3
    if not T3.go then return end
    local z = C.zone(T3.name)
    local w = RT.ww()
    local d = w and w._drawerPanel
    if not (ok and z and d) then
        T3.go = false
        Q.check(false, "K2-3: " .. tostring(T3.title) .. "'s row is in the list's view to right-click (staging)", "its zone " .. tostring(z ~= nil))
        return
    end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    local ax, ay = d:getAbsoluteX() + x, d:getAbsoluteY() + y
    local cov, by = H.covered(w, ax, ay)
    if cov then
        T3.go = false
        Q.skip(T3.label, tostring(T3.title) .. "'s row is under the " .. tostring(by) .. " on this screen: a real right-click there lands on that")
        return
    end
    local okR, err = H.atPointer(ax, ay, function() d:onRightMouseDown(x, y) end)
    if not (okR and C.isPinned(T3.name)) then
        T3.go = false
        Q.check(false, "K2-3: a right-click on " .. tostring(T3.title) .. "'s row pins it (staging)", "ran " .. tostring(okR) .. " " .. tostring(err or "")
            .. "; his pins now [" .. H.list(C.pins()) .. "]")
        return
    end
    local st = C.st()
    T3.fc0 = st and st.filteredCache
    -- Show: Ready (what the band's Show list sets; the switch is not under test)
    pcall(ZeD.CraftingCore.setShow, st, "ready")
end)
H.wait(4000, function()
    local st = C.st()
    return not S.c3.go or (st ~= nil and st.filterDirty == false and st.filteredCache ~= S.c3.fc0)
end, function(ok)
    local T3 = S.c3
    if not T3.go then return end
    T3.filtered = ok
end)
-- (its row brought into the list's view: the list stamps every row's zone, drawn or not; a row the list does not
-- hold has none)
H.wait(2500, function()
    local T3 = S.c3
    if not T3.go then return true end
    local z = C.zone(T3.name)
    if z and not C.inView(z) then C.place(T3.name, C.mid()) end
    return z ~= nil and C.inView(z)
end, function(drawn)
    local T3 = S.c3
    if not T3.go then return end
    local st = C.st()
    local rd = C.row(T3.name)
    local listed = C.listed(T3.name)
    local inPin, folded = C.inPinned(T3.name)
    local status = rd and rd.status
    local show = st and st.show
    Q.check(T3.filtered and show == "ready" and listed and inPin and not folded and drawn and status ~= nil and status ~= "craftable",
        T3.label .. ": " .. tostring(T3.title) .. ", pinned by a right-click on its row, is in the Pinned group, its row drawn (old code: Show: Ready leaves it out)",
        "Show " .. tostring(show) .. ", the list filtered again " .. tostring(T3.filtered) .. " (" .. #((st and st.filteredCache) or {}) .. " rows); listed "
        .. tostring(listed) .. ", in the Pinned group " .. tostring(inPin) .. (folded and " (folded)" or "") .. ", its row drawn in view " .. tostring(drawn)
        .. "; its status " .. tostring(status) .. " (was " .. tostring(T3.status0) .. "; craftable would be listed by Ready either way)")
end)
-- the tab as found: pins, choices, then (filtered again) the card and the scroll
Q.step(3, function()
    local T3 = S.c3
    if not T3.seen then return end
    C.pinsBack()
    C.stateBack()
end)
H.wait(4000, function()
    local st = C.st()
    return not S.c3.seen or (st ~= nil and st.filterDirty == false)
end, function()
    local T3 = S.c3
    if not T3.seen then return end
    C.cardBack()
    C.stationBack()
    T3.backDone = true
end)

-- ===================================================================== K2-8: a double-click on a closed stack
S.n8.label = "K2-8: a double-click on the closed stack Nails (50) in a crate beside him moves the whole stack into his inventory"
Q.step(5, function()
    local T8 = S.n8
    if S.dead then return end
    local ww = RT.ww()
    if not ww then return end
    H.tab("w", "loot")
    H.clearQueue()
    local sq = N.freeSq()
    T8.crate = sq and N.mkCrate(sq) or nil
    if not T8.crate then Q.skip(T8.label, "no free square beside him for a crate (or the crate could not be made)"); return end
    -- fifty nails in it, each the script's own (an add may make more than one: the extra taken away)
    local inv = T8.crate.inv
    local tries = 0
    local n = 0
    while n < 50 and tries < 80 do
        tries = tries + 1
        pcall(function() inv:AddItem("Base.Nails") end)
        n = 0
        pcall(function()
            local its = inv:getItems()
            for i = 0, its:size() - 1 do
                local it = its:get(i)
                if it and it:getFullType() == "Base.Nails" then n = n + 1 end
            end
        end)
    end
    T8.list, T8.set = {}, {}
    pcall(function()
        local its = inv:getItems()
        local all = {}
        for i = 0, its:size() - 1 do all[#all + 1] = its:get(i) end
        for _, it in ipairs(all) do
            if it:getFullType() == "Base.Nails" then
                if #T8.list < 50 then
                    T8.list[#T8.list + 1] = it
                    T8.set[it] = true
                    pcall(function() it:getModData().ZeDQA_spawned = true end)
                else
                    inv:Remove(it)
                end
            end
        end
    end)
    if #T8.list ~= 50 then Q.check(false, "K2-8: fifty nails are made in the crate (staging)", #T8.list .. " made"); return end
    -- room for them in his inventory, by the game's own test (the one its transfer action asks): a full inventory
    -- would refuse the moves, which is no fault of the double-click
    local wt = 0
    for _, it in ipairs(T8.list) do pcall(function() wt = wt + it:getUnequippedWeight() end) end
    local room = true
    pcall(function() room = H.main():hasRoomFor(S.p, wt) and true or false end)
    if not room then Q.skip(T8.label, "his inventory has no room for " .. H.num(wt) .. " kg of nails (the game's own test)"); return end
    -- the crate's list a list (not a grid), the nails' stack shut, the World window on the crate
    H.listView(inv)
    H.setStack("w", "Base.Nails", false)
    -- timed actions instant for the fifty moves (the cheat as found right after the part)
    pcall(function() S.p:setTimedActionInstantCheat(true) end)
    T8.instSet = true
    ww._containerTimer = 30
    pcall(ZeD_WorldWindow.selectContainer, inv, 200, S.pn)
    T8.go = true
end)
H.wait(8000, function()
    local T8 = S.n8
    if not T8.go then return true end
    local wc = N.wc()
    if not (wc and wc._inventory == T8.crate.inv) then return false end
    local z = N.rowZone()
    if z and H.rowShown(wc, z.id) then return true end
    -- (a fresh crate's one row stands at the list's top; the list's scroll as found goes back at the end)
    H.scrollTo("w", 0)
    return false
end, function(ok)
    local T8 = S.n8
    if not T8.go then return end
    local wc = N.wc()
    local z = ok and N.rowZone() or nil
    local stk = (z and wc and wc._stacks) and wc._stacks[z.id] or nil
    T8.rowCount = stk and stk.count or (z and 1 or 0)
    if not (z and T8.rowCount == 50) then
        T8.go = false
        Q.check(false, "K2-8: the crate's list shows Nails (50) as one closed row (staging)", "the World list on the crate "
            .. tostring(wc ~= nil and wc._inventory == T8.crate.inv) .. ", the nails' row " .. tostring(z ~= nil) .. ", its count " .. tostring(T8.rowCount))
        return
    end
    T8.rep = z.id
    -- the first click of the pair, down and up at the row's middle
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    wc._zedLastClick = nil
    local okC, err = H.atPointer(wc:getAbsoluteX() + x, wc:getAbsoluteY() + y, function() wc:onMouseDown(x, y); wc:onMouseUp(x, y) end)
    if not okC then T8.go = false; Q.check(false, "K2-8: the first click on the nails' row ran without an error", tostring(err)) end
end)
Q.step(1, function()
    local T8 = S.n8
    if not T8.go then return end
    -- the second click a frame later (inside the game's 400 ms), on the row as drawn now
    local wc = N.wc()
    local z = H.rowZone(wc, T8.rep)
    if not z then T8.go = false; Q.check(false, "K2-8: the nails' row is still there for the second click (staging)"); return end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    local okC, err = H.atPointer(wc:getAbsoluteX() + x, wc:getAbsoluteY() + y, function() wc:onMouseDown(x, y); wc:onMouseUp(x, y) end)
    T8.err = (not okC) and tostring(err) or nil
    T8.moves = N.moves()
    T8.q = H.queueText()
    T8.t0 = getTimestampMs()
end)
H.wait(30000, function()
    local T8 = S.n8
    if not T8.go then return true end
    return #H.queue() == 0 and getTimestampMs() - T8.t0 > 300
end, function(ok)
    local T8 = S.n8
    if not T8.go then return end
    local inMain, inCrate = N.count(H.main()), N.count(T8.crate.inv)
    Q.check(T8.err == nil and inMain == 50 and inCrate == 0, T8.label .. " (old code: one nail comes, 49 stay)",
        "the double-click ran " .. tostring(T8.err == nil) .. (T8.err and (": " .. T8.err) or "") .. "; right after it " .. T8.moves
        .. " moves of the nails queued ([" .. tostring(T8.q) .. "]); " .. (ok and "the queue emptied" or "the queue did not empty in 30 s")
        .. "; now " .. inMain .. " in his inventory, " .. inCrate .. " in the crate, " .. (50 - inMain - inCrate) .. " elsewhere")
end)
Q.step(3, function()
    local T8 = S.n8
    H.clearQueue()
    N.putBack()
    -- (a card the clicks opened: shut by its own X)
    if S.card0 and S.card0.w == nil then H.shutCard("w") end
    local wc = N.wc()
    if wc then wc._selectedItems = {}; wc._lastClickedItem = nil; wc._zedLastClick = nil end
end)

-- ===================================================================== K2-2: a click on a belt hand
S.b2.label = "K2-2: a left click on the belt's main hand holding the crowbar"
Q.step(5, function()
    local T2 = S.b2
    if S.dead then return end
    H.tab("c", "loot")
    H.clearQueue()
    -- his hands empty for the part (what he held goes back after)
    pcall(function() S.p:setPrimaryHandItem(nil) end)
    pcall(function() S.p:setSecondaryHandItem(nil) end)
    T2.bar = H.give("Base.Crowbar")
    H.setStack("c", "Base.Crowbar", true)
    S.seek.c = nil
    T2.go = T2.bar ~= nil
    if not T2.go then Q.check(false, "K2-2: a crowbar is given (staging)") end
end)
H.wait(6000, function()
    local T2 = S.b2
    if not T2.go then return true end
    return B.drawn() and B.hand("p") ~= nil and H.seekRow("c", T2.bar)
end, function(ok)
    local T2 = S.b2
    if not T2.go then return end
    local b, hud = B.hand("p")
    if not (B.drawn() and b and hud) then
        T2.go = false
        Q.skip(T2.label, "ZeD's belt is not on screen here (drawn " .. tostring(B.drawn()) .. ", a main hand " .. tostring(b ~= nil) .. ")")
        return
    end
    local _, _, gx, gy = B.center(b, hud)
    local cov, by = H.covered(hud, gx, gy)
    if cov then
        T2.go = false
        Q.skip(T2.label, "the belt's main hand is under the " .. tostring(by) .. " on this screen: a real click there lands on that")
        return
    end
    if ok then
        local okD, how = H.drag(H.content("c"), T2.bar, gx, gy)
        T2.dragged, T2.dragHow = okD, how
    else
        T2.dragHow = "the crowbar's row is not on view in his list"
    end
    if not T2.dragged then
        Q.skip("K2-2 (a guard): the crowbar dragged from his list onto the belt's main hand is drawn into the hand", tostring(T2.dragHow))
        -- (staging only: the game's setter puts it in his hand, so the click can be tried)
        pcall(function() S.p:setPrimaryHandItem(T2.bar) end)
    end
end)
H.wait(6000, function()
    local T2 = S.b2
    if not T2.go then return true end
    return S.p:getPrimaryHandItem() == T2.bar and #H.queue() == 0
end, function(ok)
    local T2 = S.b2
    if not T2.go then return end
    T2.dragEquipped = T2.dragged == true and ok
    -- (the drawer the drag's press opened for the crowbar's card, shut by the card's X)
    if S.card0 and S.card0.c == nil then H.shutCard("c") end
    if not ok then
        -- (the drag did not draw it into the hand: put there for the click; the second check says so)
        H.clearQueue()
        pcall(function() S.p:setPrimaryHandItem(T2.bar) end)
    end
end)
Q.step(3, function()
    local T2 = S.b2
    if not T2.go then return end
    local b, hud = B.hand("p")
    if not (b and hud and hud._drawn) then
        T2.go = false
        Q.check(false, T2.label .. ": the belt's main hand is on screen to click (staging)")
        return
    end
    local lx, ly, gx, gy = B.center(b, hud)
    -- (asked again at the click: the drag's card may have widened the Character window over the belt meanwhile)
    local cov, by = H.covered(hud, gx, gy)
    if cov then
        T2.go = false
        Q.skip(T2.label, "the belt's main hand is under the " .. tostring(by) .. " at the click on this screen: a real click there lands on that")
        return
    end
    local hit = nil
    pcall(function() hit = hud:boxAt(lx, ly) end)
    T2.held0 = S.p:getPrimaryHandItem() == T2.bar
    -- the press and the release in one frame (the belt drops a press when the real button is not down)
    local okC, err = H.atPointer(gx, gy, function() hud:onMouseDown(lx, ly); hud:onMouseUp(lx, ly) end)
    local act = B.unequipFor(T2.bar)
    T2.q = H.queueText()
    Q.check(okC and T2.held0 and hit ~= nil and hit.kind == "hand" and hit.which == "p" and act ~= nil,
        T2.label .. " queues the game's put-away for it (ISUnequipAction, as the pad's A on that hand does) (old code: the click does nothing)",
        "the click at the hand's middle (" .. H.num(gx) .. "," .. H.num(gy) .. ", the belt's own box there: " .. tostring(hit and hit.kind) .. " "
        .. tostring(hit and hit.which) .. ") ran " .. tostring(okC) .. (okC and "" or (": " .. tostring(err))) .. "; the crowbar in the main hand before "
        .. tostring(T2.held0) .. "; the queue at once [" .. tostring(T2.q) .. "], the put-away for the crowbar " .. tostring(act ~= nil))
    T2.t0 = getTimestampMs()
end)
H.wait(6000, function()
    local T2 = S.b2
    if not T2.go then return true end
    return S.p:getPrimaryHandItem() ~= T2.bar and S.p:getSecondaryHandItem() ~= T2.bar and #H.queue() == 0
end, function(ok)
    local T2 = S.b2
    if not T2.go then return end
    -- (a crowbar is a two-hand weapon: the drag puts it in both hands, the put-away takes it from both)
    local held = S.p:getPrimaryHandItem() == T2.bar or S.p:getSecondaryHandItem() == T2.bar
    local inMain = H.where(T2.bar) == H.main()
    local guardOk = (not T2.dragged) or T2.dragEquipped
    Q.check(ok and not held and inMain and guardOk,
        T2.label .. ": the crowbar leaves his hand and stays in his inventory" .. (T2.dragged and "; the drag onto the hand before it still drew it into the hand" or "")
        .. " (old code: it stays in his hand)",
        "after the click: in a hand " .. tostring(held) .. ", in his inventory " .. tostring(inMain) .. ", the queue [" .. H.queueText() .. "]"
        .. (T2.dragged and ("; the drag (" .. tostring(T2.dragHow) .. ") drew it into the hand " .. tostring(T2.dragEquipped)) or "; the drag was not staged"))
    H.clearQueue()
end)
Q.step(3, function()
    H.clearQueue()
    pcall(H.removeItem, S.b2.bar)
    H.handsBack()
end)

-- ===================================================================== K2-7: no Use on wipes, thread, a lighter
Q.step(5, function()
    local T7 = S.u7
    if S.dead then return end
    H.tab("c", "loot")
    H.clearQueue()
    for _, k in ipairs(U.KINDS) do
        T7[k.key] = H.give(k.ft)
        H.setStack("c", k.ft, true)
    end
    T7.go = true
end)
for _, k in ipairs(U.KINDS) do U.queueRead(k) end
Q.step(2, function()
    local T7 = S.u7
    if not T7.go then return end
    local p = U.KINDS[1]
    local ctrl = p.read == true and p.useDrawn == true
    for i = 2, #U.KINDS do
        local k = U.KINDS[i]
        Q.check(k.read == true and not k.useDrawn and not k.useModel and ctrl,
            "K2-7: no Use on the card of " .. k.word .. ", which the game's double-click does nothing with; the painkillers' card, read the same way, keeps its Use (old code: Use on every drainable's card)",
            U.text(k) .. "; " .. U.text(p))
    end
    -- (the last card shut by its own X; the picks let go)
    H.shutCard("c")
    local c = H.content("c")
    if c then c._selectedItems = {}; c._lastClickedItem = nil; c._zedLastClick = nil end
    for _, k in ipairs(U.KINDS) do pcall(H.removeItem, T7[k.key]) end
end)

-- ===================================================================== K2-7: a bandage dropped on a wound
Q.step(5, function()
    local T = S.d7
    if S.dead then return end
    H.clearQueue()
    T.drops = {}
    T.part = D.pickPart()
    if not T.part then Q.skip("K2-7: a bandage dropped on a wound on the Health tab", "every arm part has a wound, a bandage or stitches already"); return end
    H.tab("c", "health")
    -- (the body figure unfolded for the run: a folded figure is not drawn, and has no parts to drop on)
    local cw = RT.cw()
    if cw then
        T.foldWas = cw._healthFigureExpanded
        cw._healthFigureExpanded = true
    end
    -- god mode off for the wound's few seconds (with it the game heals a wound at once), invincible on, the guard on;
    -- instant actions off (a bandage would be put on at once)
    T.staged = true
    pcall(function() S.p:setInvincible(true) end)
    pcall(function() S.p:setGodMod(false) end)
    if S.was.inst then pcall(function() S.p:setTimedActionInstantCheat(false) end); T.instSet = true end
    T.guardT0, T.guardOn = getTimestampMs(), true
    Events.OnTick.Add(D.guard)
    T.wounded = D.wound()
    if not T.wounded then Q.check(false, "K2-7: a scratch is made on the " .. T.part.name .. " (staging)"); return end
    T.go = true
end)
H.wait(8000, function()
    local T = S.d7
    if not T.go then return true end
    local fig = D.fig()
    return D.tabUp() and D.still() and D.rowZone() ~= nil and fig ~= nil and fig._drawAtS ~= nil
end, function(ok)
    local T = S.d7
    if not T.go then return end
    local w = RT.cw()
    if not (ok and w) then
        T.go = false
        Q.check(false, "K2-7: the Health tab shows the scratch on the " .. T.part.name .. " (staging)", "the tab up " .. tostring(D.tabUp())
            .. ", its wound row " .. tostring(D.rowZone() ~= nil) .. "; the Character window on " .. tostring(w and w._activeTab))
        return
    end
    -- the tab at its top (as found after)
    local sc = w._healthScroll
    if sc then pcall(function() T.scrollWas = sc.scrollPos; sc:setScrollPos(0) end) end
    -- the bandages: in his inventory when his list shows beside the tab, else on the ground in the World window's list
    local c = H.content("c")
    local cv = false
    if c then pcall(function() cv = c:isReallyVisible() and c:getWidth() > 0 end) end
    if cv and c._inventory == H.main() then
        T.src, T.srcName = "c", "his list beside the tab"
        T.band = { H.give("Base.Bandage"), H.give("Base.Bandage") }
        H.setStack("c", "Base.Bandage", true)
    else
        T.src, T.srcName = "w", "the ground's list in the World window (his own list does not show beside the Health tab here)"
        local sq = S.p:getCurrentSquare()
        T.band = { H.addFloor(sq, "Base.Bandage", 0.3, 0.5), H.addFloor(sq, "Base.Bandage", 0.7, 0.5) }
        local ww = RT.ww()
        if ww then
            ww._containerTimer = 30
            for _, e in ipairs(ww._containers or {}) do
                if e.isFloor then
                    H.listView(e.inventory)
                    pcall(ZeD_WorldWindow.selectContainer, e.inventory, 60, S.pn)
                end
            end
        end
        H.setStack("w", "Base.Bandage", true)
    end
    if not (T.band[1] and T.band[2]) then T.go = false; Q.check(false, "K2-7: two bandages are made for the drops (staging)"); return end
    S.seek[T.src] = nil
    Q.say("K2-7 (drops): a scratch on the " .. T.part.name .. "; the bandages in " .. T.srcName .. "; god mode off, invincible on, the guard on")
end)
H.wait(8000, function()
    local T = S.d7
    if not T.go then return true end
    return H.seekRow(T.src, T.band[1])
end, function(ok)
    local T = S.d7
    if not T.go then return end
    if not ok then T.go = false; Q.check(false, "K2-7: the bandage's row is on view in " .. T.srcName .. " (staging)") end
end)
D.queueDrop(1, "the wounded part on the Health tab's body figure", D.figurePoint)
-- the tab scrolled to the part's wound row, the second bandage's row on view
Q.step(2, function() S.d7.seek = nil; S.seek[S.d7.src or "c"] = nil end)
H.wait(8000, function()
    local T = S.d7
    if not T.go then return true end
    return D.seekRowView() and H.seekRow(T.src, T.band[2])
end, function(ok)
    local T = S.d7
    if not T.go then return end
    T.why2 = nil
    -- (the bandage's row not on view is a staging fault; the wound row out of the tab's view is the drop's SKIP)
    if not ok and D.rowPoint() and not H.rowShown(H.content(T.src), T.band[2]) then
        T.why2 = "the second bandage's row is not on view in " .. T.srcName
    end
end)
D.queueDrop(2, "the wounded part's row in the Health tab's wound list", D.rowPoint, function() return S.d7.why2 end)
Q.step(3, function()
    local T = S.d7
    D.putBack()
    if T.tripped then Q.say("NOTE K2-7: the guard stopped the wound early (" .. tostring(T.tripped) .. "): the part healed, god mode on") end
end)

-- ===================================================================== put back
Q.mark()
Q.step(2, function()
    pcall(H.cancelDrags)
    H.clearQueue()
    pcall(M.putBack)
    pcall(D.putBack)
    pcall(N.putBack)
    pcall(C.pinsBack)
    pcall(C.stationBack)
    if not S.c3.backDone then pcall(C.stateBack) end
    pcall(RT.takeBack)
    for _, it in ipairs(S.made) do pcall(H.removeItem, it) end
    pcall(H.handsBack)
    pcall(H.stacksBack)
    pcall(H.foldsBack)
    pcall(H.gridBack)
    -- (the cards the run opened shut by their own X; the picks let go)
    for _, k in ipairs({ "c", "w" }) do
        if S.card0 and S.card0[k] == nil then H.shutCard(k) end
        local c = H.content(k)
        if c then c._selectedItems = {}; c._lastClickedItem = nil; c._zedLastClick = nil; c._padMarks = nil end
    end
end)
-- the tabs as found (a window shut at the start goes back to Loot before it shuts)
Q.step(3, function()
    if not S.ready then return end
    H.tab("c", S.was.tab.c or "loot")
    H.tab("w", S.was.tab.w or "loot")
end)
H.wait(3000, function()
    if not S.ready then return true end
    return H.tabOf("c") == (S.was.tab.c or "loot") and H.tabOf("w") == (S.was.tab.w or "loot") and H.settled()
end, function()
    if not S.ready then return end
    if not S.c3.backDone and S.c3.seen then pcall(C.cardBack) end
    pcall(H.viewTo, RT.cw(), S.view0.c)
    local ww = RT.ww()
    local wv = S.view0.w
    if ww and wv and wv.aInv and not H.sameView(ww, wv) and H.idxOf(ww, wv.aInv) then pcall(ZeD_WorldWindow.selectContainer, wv.aInv, 60, S.pn) end
    H.scrollTo("c", S.scroll0.c)
    H.scrollTo("w", S.scroll0.w)
    -- the columns found open, opened again
    for _, inv in ipairs(S.cols.c or {}) do pcall(ZeD_CharacterWindow.toggleColumn, inv, S.pn) end
    for _, inv in ipairs(S.cols.w or {}) do pcall(ZeD_WorldWindow.toggleColumn, inv, S.pn) end
    H.modeBack()
end)
-- (the detector's tick takes the moment's lock, if one was set; real time, at any frame rate)
Q.waitMs(400)
Q.step(1, function()
    H.modeFree()
    if not S.ready then return end
    S.holdOff = true
    -- a side found rolled away under its tab, rolled again; the roll-up timers and a window found rolled up, as found
    local cw, ww = RT.cw(), RT.ww()
    local CU = ZeD.Curtain
    if cw and S.was.rolled.c and not cw._rolled and CU and CU.roll then pcall(CU.roll, cw) end
    if ww and S.was.rolled.w and not ww._rolled and CU and CU.roll then pcall(CU.roll, ww) end
    if cw then cw._outSince = S.outWas.c end
    if ww then ww._outSince = S.outWas.w end
    if cw and S.was.shaded.c and not cw.windowShaded then pcall(function() cw:setWindowShaded(true) end) end
    if ww and S.was.shaded.w and not ww.windowShaded then pcall(function() ww:setWindowShaded(true) end) end
    -- the windows found shut, shut (the pair by its own toggle when both were)
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
    -- a window found shut: the layout the character keeps for it, as it was (the run's close saved its own)
    if not (S.was.char and S.was.world) then
        pcall(function()
            local md = S.p:getModData()
            if S.was.ws.had then md.ZeD_WinState = H.copy(S.was.ws.v) else md.ZeD_WinState = nil end
        end)
    end
    -- the places and sizes of the windows found open, at rest; one not back is set back by its own setters
    local moved = {}
    if S.was.char and H.placeBack(RT.cw(), S.was.geo.c) then moved[#moved + 1] = "Character" end
    if S.was.world and H.placeBack(RT.ww(), S.was.geo.w) then moved[#moved + 1] = "World" end
    S.moved = (#moved > 0) and table.concat(moved, " and ") or nil
end)
Q.step(10, function()
    if not S.ready then return end
    -- the things (the script's nails among them)
    local left, said, total = {}, {}, 0
    local all = {}
    for _, it in ipairs(S.made) do all[#all + 1] = it end
    for _, it in ipairs(S.n8.list or {}) do all[#all + 1] = it end
    for _, it in ipairs(all) do
        total = total + 1
        if H.where(it) ~= nil or H.onFloor(it) then
            left[#left + 1] = it
            if #said < 4 then said[#said + 1] = H.nm(it) .. (H.onFloor(it) and " on the ground" or " in a container") end
        end
    end
    local crate = N.stands(S.n8.crate)
    local hp, hs = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    local hw = S.was.hand or {}
    local md = S.p:getModData()
    local grid = H.gridSame()
    Q.check(#left == 0 and not crate and hp == hw.p and hs == hw.s and grid and #H.queue() == 0,
        "put back: nothing the script gave or made is left, the crate is gone, the lists' grid choices as found, his hands hold what they held, no action queued",
        #left .. " of " .. total .. " things left" .. ((#said > 0) and (": " .. table.concat(said, "; ")) or "")
        .. "; the crate standing " .. tostring(crate) .. "; hands " .. H.nm(hp) .. " / " .. H.nm(hs) .. " (found " .. H.nm(hw.p) .. " / " .. H.nm(hw.s)
        .. "); the grid choices as found " .. tostring(grid) .. "; the queue [" .. H.queueText() .. "]")
    -- the body
    local dead, health = true, -1
    pcall(function() dead = S.p:isDead() end)
    pcall(function() health = S.p:getBodyDamage():getOverallBodyHealth() end)
    local part = S.d7.part and D.bp() or nil
    local hurt = false
    if part then pcall(function() hurt = part:HasInjury() or part:bandaged() or part:scratched() end) end
    local god, inv, inst = nil, nil, nil
    pcall(function() god = S.p:isGodMod() and true or false end)
    pcall(function() inv = S.p:isInvincible() and true or false end)
    pcall(function() inst = S.p:isTimedActionInstantCheat() and true or false end)
    Q.check(not dead and not hurt and health >= math.min(99, (S.was.health or 100) - 1) and god == S.was.god and inv == S.was.inv
        and inst == S.was.inst and not S.d7.guardOn,
        "put back: the character is alive and unhurt, god mode, invincible and instant actions as found, the guard off",
        "dead " .. tostring(dead) .. ", health " .. H.num(health) .. " (found " .. H.num(S.was.health) .. "); the run's part (" .. tostring(S.d7.part and S.d7.part.name)
        .. ") hurt or bandaged " .. tostring(hurt) .. "; god mode " .. tostring(god) .. " (found " .. tostring(S.was.god) .. "), invincible " .. tostring(inv)
        .. " (found " .. tostring(S.was.inv) .. "), instant actions " .. tostring(inst) .. " (found " .. tostring(S.was.inst) .. ")"
        .. (S.d7.tripped and ("; the guard tripped: " .. S.d7.tripped) or ""))
    -- the map, the pause menu, the speed
    local ww = RT.ww()
    local pop = ww and ww._mapPopout
    local toolOk = not S.m6.toolTaken or ww == nil or (ww._mapActiveTool == S.m6.toolWas)
    Q.check(pop == nil and M.pauseUp() == (S.was.pause and true or false) and getGameSpeed() == S.was.speed and toolOk,
        "put back: ZeD's map closed, the pause menu as found, the game at the speed found, the map's tool as found",
        "a map open " .. tostring(pop ~= nil) .. ", the pause menu up " .. tostring(M.pauseUp()) .. ", game speed " .. H.num(getGameSpeed())
        .. " (found " .. H.num(S.was.speed) .. "), the map's tool " .. tostring(ww and ww._mapActiveTool) .. " (found " .. tostring(S.m6.toolWas) .. ")")
    -- the Crafting tab
    local T3 = S.c3
    if T3.pinsTaken then
        local w = RT.ww()
        local st = C.st()
        local k = T3.keep
        local mdPins = md.ZeD_CraftPins
        local pinsOk = (T3.mdPinsHad and H.sameList(mdPins, T3.mdPinsWas)) or (not T3.mdPinsHad and mdPins == nil)
        local listOk = (T3.pinsWas == nil) or (w ~= nil and H.sameList(w._craftPins, T3.pinsWas))
        local same = true
        if st and k and T3.seen then
            same = st.show == k.show and st.showAll == k.showAll and st.sort == k.sort and st.activeCat == k.cat and (st.search or "") == (k.search or "")
                and st.selected == k.sel and (st.pinnedCollapsed and true or false) == (k.pin and true or false)
        end
        local station = T3.stWas == nil or T3.stBack == true
        Q.check(pinsOk and listOk and same and station,
            "put back: the Crafting tab's pins (its list and the save's copy), Show, Sort, category, search, open card and a bound station as found",
            "the save's pins [" .. H.list(mdPins) .. "] (found [" .. H.list(T3.mdPinsWas) .. "]), the tab's [" .. H.list(w and w._craftPins) .. "] (found ["
            .. H.list(T3.pinsWas) .. "]); Show " .. tostring(st and st.show) .. "/" .. tostring(k and k.show) .. ", Sort " .. tostring(st and st.sort) .. "/"
            .. tostring(k and k.sort) .. ", category " .. tostring(st and st.activeCat) .. "/" .. tostring(k and k.cat) .. ", card " .. tostring(st and st.selected)
            .. "/" .. tostring(k and k.sel) .. " (now / found); a station bound again " .. tostring(station))
    end
    -- the input lock and the mode ZeD reads (vx12_wheel.lua)
    if S.lockWas ~= nil and S.was.mode ~= nil then
        local now, mode = H.lockFound(), H.mode()
        local unknown = S.was.mode == "unknown" and mode == "kbm"
        Q.check(now == S.lockWas and (mode == S.was.mode or unknown) and S.modeHeld == nil and not S.locked,
            "put back: the input lock as found, and the mode ZeD reads",
            "ZeD setup's Input lock " .. tostring(now) .. " (found " .. tostring(S.lockWas) .. "); ZeD reads " .. tostring(mode) .. " (found " .. tostring(S.was.mode) .. ")"
            .. (unknown and "; found unknown, no input since the game started, which ZeD reads as the mouse: the detector has no way back to it" or ""))
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
