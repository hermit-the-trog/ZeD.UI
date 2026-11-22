-- ZeDUI/tools/qa/kiss_loot.lua  (Nov 22 2026, QA; tag kssl): the KISS audit's pictures (Keep It Super Simple), part
-- "loot": 4K full screen, mouse and keyboard. The audit ranked where ZeD-GUI costs a time-poor new player extra steps;
-- the director decides each design call from a report page, and each call gets one honest in-game picture of the
-- friction as a player meets it today. Pictures to Zomboid/Screenshots/kiss_<name>.png (kiss_pics_run.ps1 moves them
-- to Screenshots/kiss_report/<name>.png). Manifest kiss_pics_loot.txt (the story stage, gallery_unload.lua, G1,
-- hfr_common.lua). Style and theme as the staging left them.
--   07_strip_beans      ZeD's right-click menu at its defaults (Context menu: Strip, and no pinned actions, both set for
--                       the picture) on a can of beans on its row of the Character list, right-clicked as a mouse player
--                       does (the list's own onRightMouseDown / onRightMouseUp at the row, as kiss_deck.lua: the row
--                       selected and its item card opened in the drawer, the Character window placed a card's width in
--                       from the screen's left edge so the card opens to its left): the strip of small pictures beside
--                       the row, no words on its cells, the one balloon naming only the lit first cell. The Character
--                       window held "in use" (solid) as bxr_menus.lua W15 holds it; the pointer the game reads on the row
--                       for the click, then parked off the strip once it is made
--   10_fridge_columns   inside the store, a fridge-freezer placed against a wall behind him (bxr_inv.lua's spot) with
--                       five foods in its fridge; the World window on Loot showing the Floor; a plain click on the
--                       fridge's picture on the World window's container strip (the strip's own onMouseDown at the
--                       picture's hit zone, as hfr_common.lua's S.goTab clicks a tab): the window widens into two narrow
--                       columns, the fridge and the Floor, with no container buttons' row (Take all) under either
--   11_worn_missing     on the open patch by the smoking spot, dressed in the story kit (a jacket given and worn only if
--                       he has none, the bag on his back), a crowbar held as the game equips it (a two-handed weapon:
--                       both hands), every loose thing of his main inventory moved into a crate placed beside him (the
--                       belt's, holster's and back slot's things come off their slots first: they are rows of the
--                       list); the Character window on its first tab (Loot), its list reading "Nothing here."; the World
--                       window on the Floor, where it opens (not on the crate holding his things for the picture)
--   13_floor_first      he faces the store's own counter (else a kitchen counter placed on the patch) holding six foods
--                       put in it; the World window's last container made the Floor, both windows closed, then opened
--                       with the inventory key's own handler: the World window on the Floor reading its empty line, the
--                       counter's picture on its strip unlit
--   19_drag_no_room     a school bag worn on his back (the bag he wears there set aside for the picture), filled close to
--                       its capacity with heavy things given; a hunting rifle, heavier than the room left, in the crate
--                       beside him; ZeD's own drag of the rifle started on the crate's row (the World list's onMouseDown
--                       and onMouseMove) and held over the school bag's picture on the Character window's container
--                       strip: the chip shows the rifle and its weight, nothing warns that it will not fit. The pointer
--                       the game reads is moved by swapping getMouseX / getMouseY (inside pcall, as bxr_menus.lua does)
--                       and the originals go back on the step after the picture
--   41_paused_veil      at the counter with its foods, both windows open on their lists, the game paused (ZEDQA_SPEED 0,
--                       what the game's own pause button does): the veil over both lists with its paused line
-- How it stages: ZeD's input mode locked to the mouse for the run (as bxr_menus.lua); the windows at their default
-- places (ZEDQA_LAYOUT_DEFAULT), moved to the screen's edges only when they cover the character (G1.clear), never the
-- World window before 10's click (it widens from where it stands); the pointer the game reads parked off every window
-- (getMouseX / getMouseY swapped to -9000) unless the picture is about where it points (19) or for the click itself
-- (07's right-click lands on the row, then the pointer is parked), the real pointer hidden;
-- a window held "in use" only where the pointer is in the action pictured (07 and 19 the Character window, 10 the World
-- window), the others held not in use. Every picture waits for the windows to stop moving and for 3.6 s with no new
-- Lua error (bxr_inv.lua's watch), with Messages read and no error balloon up.
-- Each picture prints "ZEDQA kssl SHOT <name> | what is in it" or "ZEDQA kssl SKIP <name> | why".
-- What it puts back: the things given (the beans, the foods, the crowbar, a jacket, the school bag and what filled it,
-- the rifle), his own things moved (back into his main inventory and onto their belt, holster and back slots, each
-- slot found again by its kind: a bag worn again gives its slot back last in the hotbar's list), his hands, the bag
-- set aside (worn again), the counter's own things and its explored mark, the fridge, the crate and any counter
-- placed, the Context menu setting, his pinned actions (the same table), the row selection and the item card 07
-- opened, the input mode lock, the windows' "in use" test, the pointer the game reads, the drag, the game speed, the
-- opened stack and the lists' scroll, the zoom, both windows' places, sizes, pins and tabs (ZEDQA_LAYOUT_BACK), the
-- pair as found; he ends at the stock spot standing, alive, unhurt and out of any car. Not undone: S.notesRead marks
-- unread Messages read before each picture (bxr_inv.lua's practice). grep "ZEDQA kssl".
local S = HFR and HFR.init and HFR.init("kssl")
if not S then return end
S.DIR = "kiss_"
local Q = S.Q
S.pic, S.objs, S.objsAll, S.held, S.stackWas = {}, {}, {}, {}, {}
S.Det = ZeD and ZeD.Input and ZeD.Input.Detector
S.BEANS = { "Base.TinnedBeans", "Base.OpenBeans" }
S.FRIDGE_FOODS = { "Base.Cheese", "Base.Butter", "Base.Steak", "Base.Chicken", "Base.Egg" }
S.COUNTER_FOODS = { "Base.TinnedBeans", "Base.CannedCorn", "Base.TinnedSoup", "Base.Crisps", "Base.Chocolate", "Base.Peanuts" }
S.WEAPONS = { "Base.Crowbar", "Base.BaseballBat" }
S.JACKETS = { "Base.Jacket_Black", "Base.Jacket_ArmyOliveDrab" }
S.SCHOOLBAGS = { "Base.Bag_Schoolbag", "Base.Bag_Schoolbag_Travel", "Base.Bag_Schoolbag_Patches" }
-- (the game's scripts: DumbBell 5.0, Plank 3.0, Hammer 1.5, Wrench 1.0, Saw 1.0; the school bag holds 15)
S.FILL = { "Base.DumbBell", "Base.DumbBell", "Base.Plank", "Base.Hammer", "Base.Wrench", "Base.Saw" }
S.RIFLES = { "Base.HuntingRifle", "Base.VarmintRifle", "Base.Shotgun" }
S.CRATES = { "carpentry_01_16", "carpentry_01_17", "carpentry_01_18", "carpentry_01_19" }
S.COUNTERS = { "fixtures_counters_01_0", "fixtures_counters_01_8" }
-- (bxr_inv.lua's fridge-freezer tiles: 0 and 4 face south, 1 and 5 east, into the room)
S.FRIDGES = { N = { "appliances_refrigeration_01_0", "appliances_refrigeration_01_4", "appliances_refrigeration_01_1" },
              W = { "appliances_refrigeration_01_1", "appliances_refrigeration_01_5", "appliances_refrigeration_01_0" } }
S.k07, S.k10, S.k11 = { name = "07_strip_beans" }, { name = "10_fridge_columns" }, { name = "11_worn_missing", moved = {} }
S.k13, S.k19, S.k41 = { name = "13_floor_first" }, { name = "19_drag_no_room" }, { name = "41_paused_veil" }

if not (ZeD and ZeD.Settings and ZeD.Settings.contextStyleOption and ZeD.InventoryRenderer and ZeD.T and ZeD.T.ctx
        and S.CWm and S.WWm and S.CWm.toggleBothPaired and S.WWm.selectContainer and ISInventoryPaneContextMenu) then
    Q.say("ERR ZeD's windows, settings or inventory list are not loaded")
    Q.start()
    return
end

-- ===================================================================== the error watch (bxr_inv.lua's)
-- The debug build's red error box comes three seconds after each Lua error and is no UI element: a picture waits until
-- no new error has come for 3.6 s (every still below), and one taken sooner says so.
S.errN, S.errAt = nil, -100000
function S.errWatch()
    local n = nil
    if getLuaDebuggerErrorCount then n = getLuaDebuggerErrorCount() end
    if n ~= nil and n ~= S.errN then
        if S.errN ~= nil then S.errAt = getTimestampMs() end
        S.errN = n
    end
end
function S.quiet() S.errWatch(); return getTimestampMs() - S.errAt > 3600 end
Events.OnPreUIDraw.Add(S.errWatch)
-- the kit's still (the windows the same for 30 frames, at most 900), with no new error for 3.6 s as well
function Q.still(n, fn)
    local st = { last = nil, same = 0 }
    Q.waitFor(n, 900, function()
        local s = G1.shape()
        if s == st.last then st.same = st.same + 1 else st.last, st.same = s, 0 end
        return st.same >= 30 and S.quiet()
    end, fn)
end

-- ===================================================================== small helpers
function S.skip(name, why) Q.notTaken(name, why); Q.say("SKIP " .. name .. " | " .. tostring(why)) end
function S.fl(v) return math.floor(tonumber(v) or 0) end
function S.scr() return S.core:getScreenWidth(), S.core:getScreenHeight() end
function S.zoom()
    local z = 1
    pcall(function() z = S.core:getZoom(S.pn) end)
    if not z or z <= 0 then z = 1 end
    return z
end
function S.sqAt(x, y) return getCell():getGridSquare(x, y, 0) end
function S.nm(it)
    if it == nil then return "nothing" end
    local n = nil
    pcall(function() n = it:getDisplayName() end)
    return tostring(n or "?")
end
-- Messages read and the error balloons dismissed before a picture (bxr_inv.lua's S.notesRead): nothing is taken out
-- of Messages, only marked read, as opening it does for a player
function S.notesRead()
    local M = ZeD.Messages
    if not (M and M.unread and M.markAllRead) then return end
    if M.readErrors then pcall(M.readErrors) end
    local un, err = 0, false
    pcall(function() un, err = M.unread() end)
    if (un or 0) > 0 then pcall(M.markAllRead) end
    local gone = 0
    if M.toasts and M.dropToast then
        for i = #M.toasts, 1, -1 do
            local t = M.toasts[i]
            if t and t.kind == "crit" then pcall(M.dropToast, t); gone = gone + 1 end
        end
    end
    if (un or 0) > 0 or gone > 0 then
        Q.say("note: before the picture " .. tostring(un) .. " unread message(s) marked read (an error among them " .. tostring(err)
            .. "), " .. gone .. " error balloon(s) dismissed")
    end
end
function S.shotOk(name, what, keepMenu)
    S.notesRead()
    if not S.quiet() then
        Q.say("NOTE " .. name .. ": a Lua error came " .. tostring(getTimestampMs() - S.errAt) .. " ms before the picture: the game's red error box may be in it")
    end
    S.shot(name, keepMenu)
    S.pic[#S.pic + 1] = name
    Q.say("SHOT " .. name .. " | " .. tostring(what))
end
-- time, not frames: cond asked every 100 ms (a UI update), at most ms; fn(true) when cond came true (bxr_menus.lua)
function S.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 400000, function()
        local now = getTimestampMs()
        st.t = st.t or now
        if st.last and now - st.last < 100 then return false end
        st.last = now
        local ok, r = pcall(cond)
        if ok and r then st.ok = true; return true end
        return now - st.t >= ms
    end, function() fn(st.ok == true) end)
end
-- the camera has stopped after a move: his place on screen the same for 20 drawn frames (at most 900) (bxr_menus.lua)
function S.settle(on)
    local st = { same = 0 }
    Q.waitFor(5, 900, function()
        if on and not on() then return true end
        if S.p:getCurrentSquare() == nil then return false end
        local v = math.floor(isoToScreenX(S.pn, S.p:getX(), S.p:getY(), 0)) .. "," .. math.floor(isoToScreenY(S.pn, S.p:getX(), S.p:getY(), 0))
        if v == st.last then st.same = st.same + 1 else st.last, st.same = v, 0 end
        return st.same >= 20
    end, function() end)
end
-- the camera's zoom to get() (nil: left as it is), a quarter step a frame, then the time it takes (bxr_menus.lua)
function S.zoomDyn(get)
    local st = {}
    Q.waitFor(2, 1200, function()
        if st.left == nil then
            local z = get()
            st.left = z and math.floor((S.core:getZoom(S.pn) - z) / 0.25 + 0.5) or 0
            st.moved = st.left ~= 0
        end
        if st.left == 0 then return true end
        S.core:doZoomScroll(S.pn, (st.left > 0) and -1 or 1)
        st.left = (st.left > 0) and (st.left - 1) or (st.left + 1)
        return st.left == 0
    end, function() end)
    Q.waitFor(1, 200, function()
        if not st.moved then return true end
        st.n = (st.n or 0) + 1
        return st.n >= 100
    end, function() if st.moved then Q.say("zoom " .. tostring(S.core:getZoom(S.pn))) end end)
end
function S.over(x, y, w, h)
    local r = G1.charRect()
    return x < r.x1 and x + w > r.x0 and y < r.y1 and y + h > r.y0
end

-- ===================================================================== the open patch (bxr_menus.lua's)
-- a bare square in the open
function S.goodSq(sq)
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree() and sq:isOutside()
            and sq:getRoom() == nil and sq:getObjects():size() <= 3 and sq:getWorldObjects():size() == 0
            and sq:getVehicleContainer() == nil and sq:getMovingObjects():size() == 0
    end)
    return good and sq or nil
end
-- the squares up to three deep on the camera side of (x, y): open sky, no tree, no car
S.AHEAD = { { 2, 0 }, { 0, 2 }, { 2, 1 }, { 1, 2 }, { 2, 2 }, { 3, 1 }, { 1, 3 }, { 3, 2 }, { 2, 3 }, { 3, 3 } }
function S.clearAhead(x, y)
    for _, o in ipairs(S.AHEAD) do
        local sq = S.sqAt(x + o[1], y + o[2])
        local ok = false
        if sq then
            pcall(function() ok = sq:isOutside() and sq:getRoom() == nil and not sq:HasTree() and sq:getVehicleContainer() == nil end)
        end
        if not ok then return false end
    end
    return true
end
function S.patchAt(x, y, lo, hi)
    for dy = lo, hi do
        for dx = lo, hi do
            if not S.goodSq(S.sqAt(x + dx, y + dy)) then return false end
        end
    end
    return true
end
function S.findPatch(cx, cy)
    for _, r in ipairs({ { -3, 2 }, { -2, 2 } }) do
        local best, bs = nil, 1e9
        for dy = -14, 14 do
            for dx = -14, 14 do
                local sc = math.abs(dx) + math.abs(dy) - (dx + dy) * 0.25
                if sc < bs and S.patchAt(cx + dx, cy + dy, r[1], r[2]) and S.clearAhead(cx + dx, cy + dy) then best, bs = { x = cx + dx, y = cy + dy, lo = r[1] }, sc end
            end
        end
        if best then return best end
    end
    return nil
end
function S.home(dir) if S.c then G1.tp({ S.c.x, S.c.y }, dir or "SE") end end
-- the way from (x, y) to (tx, ty), as IsoDirections names it
function S.dirTo(x, y, tx, ty)
    local dx, dy = tx - x, ty - y
    local ax, ay = math.abs(dx), math.abs(dy)
    local ns = (dy < 0) and "N" or "S"
    local ew = (dx > 0) and "E" or "W"
    if ax <= ay * 0.42 then return ns end
    if ay <= ax * 0.42 then return ew end
    return ns .. ew
end

-- ===================================================================== the pointer the game reads, the menus
-- Mouse.setXY does not move the pointer the game's Lua reads (ISUIElement.lua:339-350 getMouseX/Y read the globals
-- getMouseX / getMouseY): the globals are swapped for a spot and back (bxr_menus.lua S.mouseOn / S.mouseOff)
function S.mouseOn(x, y)
    S.fx, S.fy = x, y
    if S.mouseSwapped then return end
    S.realMX, S.realMY = getMouseX, getMouseY
    S.mouseSwapped = true
    pcall(function()
        getMouseX = function() return S.fx end
        getMouseY = function() return S.fy end
    end)
end
function S.mouseOff()
    if not S.mouseSwapped then return end
    pcall(function() getMouseX, getMouseY = S.realMX, S.realMY end)
    S.mouseSwapped = false
end
function S.ctxOpt() return ZeD.Settings.contextStyleOption end
function S.style(v) if v ~= nil then pcall(function() S.ctxOpt():setValue(v) end) end end
function S.vmenu() local v = nil; pcall(function() v = getPlayerContextMenu(S.pn) end); return v end
function S.menu() local v = S.vmenu(); return v and v._zedMenu or nil end
function S.closeMenu()
    local m = S.menu()
    if m then pcall(m.close, m) end
    local v = S.vmenu()
    pcall(function() if v and not v._zedMenu and v.closeAll and v:isVisible() then v:closeAll() end end)
    S.mouseOff()
end
function S.menuSettled()
    if S.menu() then return true end
    local v = S.vmenu()
    if not v then return true end
    return v._zedFailed == true
end

-- ===================================================================== the input mode ZeD reads (bxr_menus.lua's)
function S.lockFound()
    local key = nil
    pcall(function()
        local o = S.opt("inputModeLock")
        local keys = ZeD.Settings.inputLockKeys
        if o and keys then key = keys[o:getValue() or 1] end
    end)
    if key == nil then pcall(function() local md = S.p:getModData().ZeD_Gamepad; key = md and md.inputModeLock end) end
    return key or "auto"
end
-- mode "kbm" (a menu anchors at the click, as a mouse player's does); nil or false puts back the lock found
function S.lock(mode)
    if not (S.Det and S.Det.setLockedMode) then return end
    pcall(function()
        if S.lockWas == nil then S.lockWas = S.lockFound() end
        if mode then
            S.Det.setLockedMode(mode)
            S.locked = true
            return
        end
        if not S.locked then return end
        S.locked = false
        S.Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then S.Det.setLockedMode(S.lockWas) end
    end)
end

-- ===================================================================== "in use"
-- A window is "in use" (solid; See-through drawn otherwise in Dark) while ZeD_Window:pointerOn says so, and that is the
-- REAL pointer (Organisms.lua:1706 pointerOn = isMouseOver; :418 _inUse). The script's pointer is not the real one, so
-- the test is held to what the picture's player does (bxr_menus.lua:910-918 S.holdChar); nil gives the window's own back
function S.holdWin(w, val)
    if not w then return end
    w.pointerOn = function() return val end
    S.held[#S.held + 1] = w
end
function S.unhold()
    for _, w in ipairs(S.held) do w.pointerOn = nil end
    S.held = {}
end

-- ===================================================================== a row of the Character list (bxr_menus.lua's)
function S.openStackOf(it)
    local c, ft = S.cc(), nil
    pcall(function() ft = it:getFullType() end)
    if not (c and ft) then return end
    c._expandedStacks = c._expandedStacks or {}
    if S.stackWas[ft] == nil then S.stackWas[ft] = c._expandedStacks[ft] or false end
    c._expandedStacks[ft] = true
    for _, cs in ipairs(c._colStates or {}) do cs.expandedStacks = cs.expandedStacks or c._expandedStacks; cs.expandedStacks[ft] = true end
end
function S.stacksBack()
    local c = S.cc()
    for ft, v in pairs(S.stackWas) do
        if c and c._expandedStacks then c._expandedStacks[ft] = (v ~= false) and v or nil end
        for _, cs in ipairs((c and c._colStates) or {}) do if cs.expandedStacks then cs.expandedStacks[ft] = (v ~= false) and v or nil end end
    end
    S.stackWas = {}
end
-- both lists back at their top
function S.scrollTop()
    for _, c in ipairs({ S.cc() or false, S.wc() or false }) do
        if c and c._scroll and c._scroll.setScrollPos then pcall(function() c._scroll:setScrollPos(0) end) end
    end
    S.seekPos = nil
end
-- the row whole inside the list's view (bxr_inv.lua, kiss_deck.lua; InventoryRenderer.lua:2931-2933 _rowView): a row
-- past the view's foot still has its zone, drawn cut off
function S.rowShown(c, item)
    local z = c and item and S.zone(c, item)
    local rv = c and c._rowView
    if not (z and rv and rv.top and rv.bottom) then return false end
    return z.y >= rv.top and z.y + z.h <= rv.bottom
end
-- hfr_common.lua's S.seekRow: the list scrolled a step at a time until the row stands whole in its view
function S.seekShown(c, item)
    if S.rowShown(c, item) then return true end
    local sc = c and c._scroll
    if sc and sc.setScrollPos then
        S.seekPos = (S.seekPos or -0.1) + 0.1
        if S.seekPos > 1.001 then S.seekPos = 0 end
        pcall(function() sc:setScrollPos(S.seekPos) end)
    end
    return false
end

-- ===================================================================== 07: a player's right-click on the row
-- (QA review, Nov 22: the menu was made straight with ISInventoryPaneContextMenu.createMenu, so the row stayed
-- unselected and no card opened, which no mouse player sees; kiss_deck.lua's 07_deck_strip is staged the list's way.)
-- The list's own right-click (ZeD_CharacterWindow.lua:7419-7450 content.onRightMouseDown / onRightMouseUp, as
-- kiss_deck.lua and the release test's rt_menus.lua drive it): :552 _rmbMenuItems makes the row the selection and
-- updateDrawer opens its item card in the drawer (:154 ITEM_CARD_W, 220 units; the drawer grows the window to the left
-- of its anchored right edge, :5197-5209), then the game's inventory menu is made at the pointer the game reads
-- (Overrides/ContextMenu.lua:229-258), which ZeD shows as its strip (:386-400)
S.CARD_U = 220
-- the Character window a card's width in from the screen's left edge (G1.clear's margin), clear of him, so the card
-- opens to its left and the list stays under the strip (kiss_deck.lua S.placeForCard); true when the card has room
function S.placeForCard()
    local w = S.CW()
    if not w then return false end
    local m, card = ZeD.T.px(12), ZeD.T.px(S.CARD_U)
    local x = m + card
    local r = G1.charRect()
    if x + w:getWidth() > r.x0 then x = math.max(m, r.x0 - w:getWidth() - 1) end
    if w:getX() ~= x then
        w:setX(x)
        if w._anchorRightEdge ~= nil then w._anchorRightEdge = x + w:getWidth() end
    end
    return x - m >= card
end
-- the selection as found (its things), kept before the right-click
function S.selNow()
    local c = S.cc()
    local t = {}
    for it in pairs((c and type(c._selectedItems) == "table" and c._selectedItems) or {}) do t[#t + 1] = it end
    return t
end
-- the selection emptied and the card shut (bxr_inv.lua S.shutCard: emptied in place, the list binds its column's own
-- table again every frame), then the things selected before the right-click put back in the same table
function S.cardShut()
    local K = S.k07
    if not K.clicked then return end
    K.clicked = nil
    local c, w = S.cc(), S.CW()
    if not (c and w) then return end
    local sel = (type(c._selectedItems) == "table") and c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    c._selectedItems = sel
    c._lastClickedItem = nil
    for _, cs in ipairs(c._colStates or {}) do
        if type(cs.selectedItems) == "table" and cs.selectedItems ~= sel then for k in pairs(cs.selectedItems) do cs.selectedItems[k] = nil end end
        cs.lastClickedItem = nil
    end
    if w._updateDrawer then pcall(w._updateDrawer, c) end
    local one = (#(c._colStates or {}) == 1) and c._colStates[1] or nil
    for _, it in ipairs(K.selWas or {}) do
        sel[it] = true
        if one and type(one.selectedItems) == "table" then one.selectedItems[it] = true end
    end
end
-- his pinned actions (ContextMenuRegistry.lua:925-996: player modData ZeD_PinnedContextIds, { id = true }; a pinned
-- action comes first in its group, applyPins): none for the strip, ZeD's default; the same table back after
function S.count(t)
    local n = 0
    for _ in pairs((type(t) == "table") and t or {}) do n = n + 1 end
    return n
end
function S.pinsAside()
    if S.was.pinsAside then return end
    local md = nil
    pcall(function() md = S.p:getModData() end)
    if not md then return end
    S.was.ctxPins = md.ZeD_PinnedContextIds
    S.was.nPins = S.count(md.ZeD_PinnedContextIds)
    S.was.pinsAside = true
    md.ZeD_PinnedContextIds = {}
end
function S.pinsBack()
    if not S.was.pinsAside then return end
    local md = nil
    pcall(function() md = S.p:getModData() end)
    if md then md.ZeD_PinnedContextIds = S.was.ctxPins end
    S.was.pinsAside = nil
end
-- a window's box, and its words
function S.box(w)
    if not w then return nil end
    return { x = S.fl(w:getX()), y = S.fl(w:getY()), w = S.fl(w:getWidth()), h = S.fl(w:getHeight()) }
end
function S.boxWord(b)
    if not b then return "none" end
    return b.x .. "," .. b.y .. " " .. b.w .. "x" .. b.h
end

-- ===================================================================== things
function S.exists(ft)
    local found = nil
    pcall(function() found = getScriptManager():FindItem(ft) end)
    return found ~= nil
end
-- a thing of type ft made in inv (his main inventory when nil), kept in S.made (hfr_common.lua's S.takeMade takes it)
function S.addTo(inv, ft)
    inv = inv or S.p:getInventory()
    if not (inv and S.exists(ft)) then return nil end
    local it = nil
    pcall(function() it = inv:AddItem(ft) end)
    if it then S.made[#S.made + 1] = it end
    return it
end
function S.giveFirst(list, inv)
    for _, ft in ipairs(list) do
        local it = S.addTo(inv, ft)
        if it then return it end
    end
    return nil
end
function S.wornSet()
    local set = {}
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do
            local w = wi:get(i)
            local it = w and w:getItem() or nil
            if it then set[it] = true end
        end
    end)
    return set
end
function S.wornNames()
    local out = {}
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do
            local w = wi:get(i)
            local it = w and w:getItem() or nil
            if it and #out < 16 then out[#out + 1] = S.nm(it) end
        end
    end)
    return table.concat(out, ", ")
end
function S.wornHas(pat)
    local has = false
    for it in pairs(S.wornSet()) do
        local ft = ""
        pcall(function() ft = tostring(it:getFullType()) end)
        if ft:find(pat, 1, true) then has = true end
    end
    return has
end
-- worn where it goes, when nothing is there (bxr_inv.lua's way: a bag's canBeEquipped, else its body location)
function S.wearIt(it)
    if not it then return false end
    local loc = nil
    pcall(function()
        if instanceof(it, "InventoryContainer") then loc = it:canBeEquipped() end
        if loc == nil or loc == "" then loc = it:getBodyLocation() end
    end)
    if loc == nil or loc == "" then return false end
    local busy = nil
    pcall(function() busy = S.p:getWornItem(loc) end)
    if busy then return false end
    pcall(function() S.p:setWornItem(loc, it) end)
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
    local on = false
    pcall(function() on = S.p:getWornItem(loc) == it end)
    return on and true or false
end
-- a thing made here off him and gone
function S.drop(it)
    if not it then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    if S.wornSet()[it] then
        pcall(function() S.p:removeWornItem(it, false) end)
        pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
    end
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
function S.handsBack()
    pcall(function() if S.p:getPrimaryHandItem() ~= S.was.h1 then S.p:setPrimaryHandItem(S.was.h1) end end)
    pcall(function() if S.p:getSecondaryHandItem() ~= S.was.h2 then S.p:setSecondaryHandItem(S.was.h2) end end)
end
-- one of his own things moved into dst, recorded in rec with the container it came from
function S.moveTo(it, dst, rec)
    if not (it and dst) then return false end
    local src = nil
    pcall(function() src = it:getContainer() end)
    if not src or src == dst then return false end
    pcall(function() src:Remove(it) end)
    pcall(function() dst:AddItem(it) end)
    local now = nil
    pcall(function() now = it:getContainer() end)
    if now == dst then rec[#rec + 1] = { it = it, from = src }; return true end
    if now == nil then pcall(function() src:AddItem(it) end) end
    return false
end
-- each back into the exact container it came from; the count that did not get there
function S.moveBackList(rec)
    local lost = 0
    for i = #(rec or {}), 1, -1 do
        local e = rec[i]
        local now = nil
        pcall(function() now = e.it:getContainer() end)
        if now ~= e.from then
            if now then pcall(function() now:Remove(e.it) end) end
            pcall(function() e.from:AddItem(e.it) end)
            pcall(function() now = e.it:getContainer() end)
            if now ~= e.from then lost = lost + 1 end
        end
    end
    return lost
end
-- what a container holds by weight (the game's own sum)
function S.wt(inv)
    local w = 0
    if inv then pcall(function() w = inv:getCapacityWeight() end) end
    return tonumber(w) or 0
end
-- every loose thing of his main inventory: not worn, not in a hand, not hidden (the list shows exactly these,
-- InventoryRenderer.lua:2065-2096 heldSet: only what he wears and holds leaves his own list)
function S.looseThings()
    local out = {}
    local worn = S.wornSet()
    local h1, h2 = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    pcall(function()
        local items = S.p:getInventory():getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if it and not worn[it] and it ~= h1 and it ~= h2 and not it:isHidden() then out[#out + 1] = it end
        end
    end)
    return out
end

-- ===================================================================== the belt, holster and back slots
function S.hb()
    local hb = nil
    if getPlayerHotbar then pcall(function() hb = getPlayerHotbar(S.pn) end) end
    return hb
end
-- each thing on a slot, with the slot's kind: a bag taken off and worn again gives its slot back at the END of the
-- hotbar's list (ISHotbar.lua:434-547 refresh: a removed slot is dropped and the rest close up, a new one is added
-- last), so a slot is found again by its kind (:408 getThisSlotIndex), not by its old number
function S.hotSnap()
    local out = {}
    local hb = S.hb()
    if hb and hb.attachedItems then
        for i, it in pairs(hb.attachedItems) do
            local slot = hb.availableSlot and hb.availableSlot[i] or nil
            out[#out + 1] = { i = i, it = it, st = slot and slot.slotType or nil }
        end
    end
    return out
end
-- on a slot now, whichever (its own slot number, ISHotbar.lua:386 reloadIcons)
function S.onSlot(hb, it)
    local k = -1
    pcall(function() k = it:getAttachedSlot() end)
    return type(k) == "number" and k > -1 and hb.attachedItems ~= nil and hb.attachedItems[k] == it
end
-- the things that were on a slot put back on it (gallery_story_teardown.lua's way: ISHotbar:attachItem, no animation);
-- the count on a slot now, of the count snapped
function S.hotBack(snap)
    snap = snap or {}
    local hb = S.hb()
    if not hb then return 0, #snap end
    pcall(function() hb:refresh() end)
    local n = 0
    for _, x in ipairs(snap) do
        local on = S.onSlot(hb, x.it)
        if not on then
            local i = x.i
            if x.st then
                local j = nil
                pcall(function() j = hb:getThisSlotIndex(x.st) end)
                if j then i = j end
            end
            local slot = hb.availableSlot and hb.availableSlot[i] or nil
            local here = false
            pcall(function() here = x.it:getContainer() == S.p:getInventory() end)
            local att = nil
            if slot and slot.def and slot.def.attachments then pcall(function() att = slot.def.attachments[x.it:getAttachmentType()] end) end
            if att and here and not (hb.attachedItems and hb.attachedItems[i]) then
                pcall(function() hb:attachItem(x.it, att, i, slot.def, false) end)
            end
            on = S.onSlot(hb, x.it)
        end
        if on then n = n + 1 end
    end
    return n, #snap
end

-- ===================================================================== placed tiles
-- every container of a placed object marked explored at once: the World window fills an unexplored one with the
-- game's loot when it lists it (ZeD_WorldWindow.lua:2986-2994), and these hold only what the picture puts in
function S.explore(o)
    pcall(function()
        local n = o:getContainerCount()
        for i = 0, n - 1 do
            local c = o:getContainerByIndex(i)
            if c then c:setExplored(true) end
        end
    end)
end
-- the first tile of names that stands on sq with a container (of type want, if given): object, container, name
-- (bxr_inv.lua's fridge and zedqa_deep_run.lua's tileObject: IsoObject.new, AddTileObject, the sprite's containers)
function S.placeTile(sq, names, want)
    if not sq then return nil end
    for _, name in ipairs(names) do
        if getSprite(name) then
            local o = nil
            pcall(function() o = IsoObject.new(sq, name, nil, false) end)
            if o then
                pcall(function() sq:AddTileObject(o) end)
                pcall(function() o:createContainersFromSpriteProperties() end)
                local inv = nil
                pcall(function() inv = (want and o:getContainerByType(want)) or o:getContainer() end)
                if inv then
                    S.explore(o)
                    S.objs[#S.objs + 1] = o
                    S.objsAll[#S.objsAll + 1] = o
                    return o, inv, name
                end
                S.removeObj(o)
            end
        end
    end
    return nil
end
-- still standing on its square (a removed object is asked nothing more)
function S.onSquare(o)
    local sq, on = nil, false
    if o then pcall(function() sq = o:getSquare() end) end
    if sq then pcall(function() on = sq:getObjects():contains(o) end) end
    return on and true or false, sq
end
function S.removeObj(o)
    local on, sq = S.onSquare(o)
    if not on then return end
    pcall(function() sq:transmitRemoveItemFromSquare(o) end)
    pcall(function() if sq:getObjects():contains(o) then sq:RemoveTileObject(o) end end)
end
function S.removeAll()
    for _, o in ipairs(S.objs) do S.removeObj(o) end
    S.objs = {}
end
function S.standing()
    local n = 0
    for _, o in ipairs(S.objsAll) do if S.onSquare(o) then n = n + 1 end end
    return n
end

-- ===================================================================== the store (bxr_inv.lua's freezer spot)
function S.roomOf(sq)
    local r = nil
    if sq then pcall(function() r = sq:getRoom() end) end
    return r
end
-- in the store: the site's box and a room named fossoil (STORY.inRoom, with no index of a missing room)
function S.inStore(x, y)
    local s = STORY and STORY.site
    if not s or x < s.x0 or x > s.x1 or y < s.y0 or y > s.y1 then return false end
    local nm = nil
    local r = S.roomOf(S.sqAt(x, y))
    if r then pcall(function() nm = r:getName() end) end
    return nm ~= nil and tostring(nm):lower():find("fossoil", 1, true) ~= nil
end
function S.storeFloor()
    local out = {}
    for _, q in ipairs((STORY and STORY.F and STORY.F.floor) or {}) do out[#out + 1] = q end
    local st = S.P.stock
    if #out == 0 and st then
        for dy = -8, 8 do for dx = -8, 8 do out[#out + 1] = { st[1] + dx, st[2] + dy } end end
    end
    return out
end
function S.sqFree(sq)
    if sq == nil then return false end
    local ok = false
    pcall(function() ok = sq:isFree(false) and sq:getVehicleContainer() == nil end)
    return ok and true or false
end
-- no door and no window on the square (a fridge is not put in front of one)
function S.plainWall(sq)
    local plain = true
    pcall(function()
        local objs = sq:getObjects()
        for i = 0, objs:size() - 1 do
            local o = objs:get(i)
            if instanceof(o, "IsoDoor") or instanceof(o, "IsoWindow") then plain = false end
        end
    end)
    return plain
end
function S.roomFree(x, y, room)
    local n = S.sqAt(x, y)
    return S.sqFree(n) and room ~= nil and S.roomOf(n) == room
end
-- a square of the room with its floor and nothing else
function S.bareSq(x, y, room)
    if not S.roomFree(x, y, room) then return false end
    local n = S.sqAt(x, y)
    local k, w = 9, 9
    pcall(function() k = n:getObjects():size(); w = n:getWorldObjects():size() end)
    return k <= 1 and w == 0
end
S.FRONT6 = { { 1, 0 }, { 0, 1 }, { 1, 1 }, { 2, 1 }, { 1, 2 }, { 2, 2 } }
S.BEHIND = { { 0, -1, "N" }, { -1, 0, "W" } }
S.FAR3 = { { 2, 1 }, { 1, 2 }, { 2, 2 } }
-- where he stands (q) and the fridge's square behind him (north, then west: the far side from the camera) whose far
-- edge is a wall of the room (pass 1; pass 2 the room's end); the squares in front of him bare floor (strict 1)
function S.fridgeAt(q, room, strict, pass, st)
    local here = S.sqAt(q[1], q[2])
    if not here then return nil end
    local front = S.roomFree(q[1], q[2], room) and S.roomFree(q[1] + 1, q[2], room) and S.roomFree(q[1], q[2] + 1, room)
        and S.roomFree(q[1] + 1, q[2] + 1, room)
    if front and strict == 1 then
        for _, d in ipairs(S.FRONT6) do
            if front and not S.bareSq(q[1] + d[1], q[2] + d[2], room) then front = false end
        end
    end
    if not front then return nil end
    local best = nil
    for _, o in ipairs(S.BEHIND) do
        local f = S.sqAt(q[1] + o[1], q[2] + o[2])
        local back = S.sqAt(q[1] + 2 * o[1], q[2] + 2 * o[2])
        local ok = false
        if S.sqFree(f) and back ~= nil and S.roomOf(f) == room and S.roomOf(back) ~= room and S.plainWall(f) then
            pcall(function()
                ok = here:canReachTo(f) and (pass == 2 or (f:getWall(o[3] == "N") ~= nil and not f:canReachTo(back)))
            end)
        end
        if ok then
            local score = 0
            for _, d in ipairs(S.FAR3) do
                if S.roomFree(q[1] + d[1], q[2] + d[2], room) then score = score + 10 end
            end
            if o[3] == "N" then score = score + 5 end
            score = score - (math.abs(q[1] - st[1]) + math.abs(q[2] - st[2])) * 0.1
            if not best or score > best.score then best = { score = score, q = { q[1], q[2] }, f = f, side = o[3], pass = pass, strict = strict } end
        end
    end
    return best
end
function S.freezerSpot()
    local st = S.P.stock
    if not st then return nil end
    local room = S.roomOf(S.sqAt(st[1], st[2]))
    if not room then return nil end
    for strict = 1, 2 do
        for pass = 1, 2 do
            local best = nil
            for _, q in ipairs(S.storeFloor()) do
                local b = S.fridgeAt(q, room, strict, pass, st)
                if b and (not best or b.score > best.score) then best = b end
            end
            if best then return best end
        end
    end
    return nil
end

-- ===================================================================== the crate on the patch
-- north, west or north-west of him: in his reach, never between him and the camera (it looks from the south-east)
S.CRATE_AT = { { 0, -1 }, { -1, 0 }, { -1, -1 } }
function S.crateHere()
    if S.crate then return true end
    if not S.c then return false end
    local here = S.sqAt(S.c.x, S.c.y)
    for _, o in ipairs(S.CRATE_AT) do
        local sq = S.goodSq(S.sqAt(S.c.x + o[1], S.c.y + o[2]))
        local reach = false
        if sq and here then pcall(function() reach = here:canReachTo(sq) and true or false end) end
        if sq and reach then
            local obj, inv, name = S.placeTile(sq, S.CRATES)
            if inv then
                S.crateObj, S.crate, S.crateName = obj, inv, name
                Q.say("a crate (" .. tostring(name) .. ") placed at " .. (S.c.x + o[1]) .. "," .. (S.c.y + o[2]) .. ", beside him on the patch")
                return true
            end
        end
    end
    return false
end
function S.crateBack()
    if #(S.k11.moved or {}) > 0 then S.k11back() end
    if S.crateObj then S.removeObj(S.crateObj) end
    S.crateObj, S.crate = nil, nil
end

-- ===================================================================== the counter
function S.counterEntry()
    local q = S.P and S.P.counter
    local F = STORY and STORY.F
    if not (q and F) then return nil end
    for _, e in ipairs(F.counters or {}) do
        if e.x == q[1] and e.y == q[2] and e.inv and e.o then return e end
    end
    return nil
end
-- nothing on the floor in his reach (the World window's Floor lists the 3 x 3 round him, ZeD_WorldWindow.lua:2865-2902)
function S.floorBare(x, y)
    local bare = true
    for dy = -1, 1 do
        for dx = -1, 1 do
            local sq = S.sqAt(x + dx, y + dy)
            if sq then pcall(function() if sq:getWorldObjects():size() > 0 then bare = false end end) end
        end
    end
    return bare
end
-- a square beside the counter to stand on, in the store and in reach of it: east or south of it first (the counter
-- behind him from the camera), then the one with a bare floor round him, then open floor in front of him
S.STAND4 = { { 1, 0, 30 }, { 0, 1, 30 }, { -1, 0, 0 }, { 0, -1, 0 } }
S.FRONT3 = { { 1, 0 }, { 0, 1 }, { 1, 1 } }
function S.counterStand(x, y)
    local csq = S.sqAt(x, y)
    if not csq then return nil end
    local best, bs = nil, -1e9
    for _, o in ipairs(S.STAND4) do
        local sx, sy = x + o[1], y + o[2]
        local sq = S.sqAt(sx, sy)
        local ok = false
        if S.sqFree(sq) and S.inStore(sx, sy) then pcall(function() ok = sq:canReachTo(csq) and true or false end) end
        if ok then
            local bare = S.floorBare(sx, sy)
            local sc = o[3] + (bare and 20 or 0)
            for _, f in ipairs(S.FRONT3) do
                if S.sqFree(S.sqAt(sx + f[1], sy + f[2])) then sc = sc + 5 end
            end
            if sc > bs then best, bs = { x = sx, y = sy, bare = bare, cam = o[3] > 0 }, sc end
        end
    end
    return best
end
-- the counter staged once for 13 and 41: its own things set aside (kept, the same things go back), its explored mark
-- kept (set while the foods are in it, so the World window adds no loot of its own), six foods put in
function S.stageCounter()
    if S.cnt and S.cnt.inv then return true end
    local K = { own = {}, foods = {} }
    S.cnt = K
    local e = S.counterEntry()
    local st = e and S.counterStand(e.x, e.y) or nil
    if e and st then
        K.obj, K.inv, K.x, K.y, K.st = e.o, e.inv, e.x, e.y, st
        K.how = "the store's own counter (" .. tostring(e.t) .. ")"
    elseif S.c then
        -- none to stand at in the store: a kitchen counter placed on the open patch, west of him
        local sq = S.goodSq(S.sqAt(S.c.x - 1, S.c.y))
        local o, inv = nil, nil
        if sq then o, inv = S.placeTile(sq, S.COUNTERS) end
        if inv then
            K.obj, K.inv, K.x, K.y, K.placed = o, inv, S.c.x - 1, S.c.y, true
            K.st = { x = S.c.x, y = S.c.y, bare = S.floorBare(S.c.x, S.c.y) }
            K.how = "a kitchen counter placed on the open patch (NOTE " .. (e and "no square to stand at by the store's counter" or "the store's counter spot holds no counter") .. ")"
        end
    end
    if not K.inv then
        K.why = "no counter: " .. (e and "no free square of the store in reach of its counter" or "STORY.P.counter holds no counter") .. ", and none could be placed on the patch"
        return false
    end
    K.face = S.dirTo(K.st.x + 0.5, K.st.y + 0.5, K.x + 0.5, K.y + 0.5)
    pcall(function() K.expl = K.inv:isExplored() end)
    pcall(function() K.inv:setExplored(true) end)
    local own = {}
    pcall(function()
        local items = K.inv:getItems()
        for i = 0, items:size() - 1 do own[#own + 1] = items:get(i) end
    end)
    for _, it in ipairs(own) do
        pcall(function() K.inv:Remove(it) end)
        K.own[#K.own + 1] = it
    end
    for _, ft in ipairs(S.COUNTER_FOODS) do
        local it = S.addTo(K.inv, ft)
        if it then K.foods[#K.foods + 1] = it end
    end
    return true
end
function S.counterBack()
    local K = S.cnt
    if not K then return end
    for _, it in ipairs(K.foods or {}) do S.drop(it) end
    if K.inv then
        for _, it in ipairs(K.own or {}) do
            pcall(function() if it:getContainer() == nil then K.inv:AddItem(it) end end)
        end
        if K.expl ~= nil then pcall(function() K.inv:setExplored(K.expl == true) end) end
    end
    if K.placed and K.obj then S.removeObj(K.obj) end
    S.cnt = nil
end

-- ===================================================================== the windows
function S.ciOf(w, inv)
    if not (w and inv) then return nil end
    for i, c in ipairs(w._containers or {}) do if c.inventory == inv then return i end end
    return nil
end
function S.invName(w, inv)
    for _, c in ipairs((w and w._containers) or {}) do
        if c.inventory == inv then return tostring(c.name) end
    end
    return "?"
end
function S.floorInv()
    local fl = nil
    pcall(function() fl = S.WWm.getFloorContainer(S.pn) end)
    return fl
end
-- the World window on Loot's anchor list, the Floor: the last container, shown, no column added
-- (ZeD_WorldWindow.lua:3722, the floor is always last and the active one at open)
function S.worldOnFloor()
    local w = S.WW()
    if not w then return false end
    local n = #(w._containers or {})
    local c = (n > 0 and w._activeContainer) and w._containers[w._activeContainer] or nil
    return n > 0 and w._activeContainer == n and c ~= nil and c.isFloor == true and w._mainVisible == true and #(w._mcSelected or {}) == 0
end
-- a container's picture wholly inside the strip's list area (ZeD_WorldWindow.lua:3396-3403 win._stripLay: listY, listH;
-- its hit zone is kept even while scrolled out of view, :3495-3496)
function S.inView(w, z)
    local L = w and w._stripLay or nil
    if not (L and z and L.listY and L.listH) then return false end
    return z.y >= L.listY and z.y + z.h <= L.listY + L.listH
end
-- a container's picture lit on the World window's strip (shown, a column or viewed; ZeD_WorldWindow.lua:3421-3423)
function S.isLit(w, ci)
    if not (w and ci) then return false end
    if ci == w._viewedContainer then return true end
    if ci == w._activeContainer and (#(w._mcSelected or {}) == 0 or w._mainVisible) then return true end
    for _, j in ipairs(w._mcSelected or {}) do if j == ci then return true end end
    return false
end
-- one list in each window: a column added on Loot taken off, one a frame (true when none is left)
function S.noColumns()
    local done = true
    for _, pair in ipairs({ { S.CW(), S.CWm }, { S.WW(), S.WWm } }) do
        local w, mod = pair[1], pair[2]
        local sel = w and w._mcSelected
        if sel and #sel > 0 and mod.toggleColumn then
            local c = w._containers and w._containers[sel[1]]
            if c and c.inventory then pcall(mod.toggleColumn, c.inventory, S.pn); done = false end
        end
    end
    return done
end
-- both windows at their default places, pinned, on Loot (the prelude's own reset)
function S.homeLayout()
    if ZEDQA_LAYOUT_DEFAULT then pcall(ZEDQA_LAYOUT_DEFAULT, "kssl") else pcall(function() ZeD_Window.resetLayout() end) end
end
-- the World window reads its containers again on the next frame
function S.dirty()
    local w = S.WW()
    if w then w._containersDirty = true; w._containerTimer = 30 end
end
-- the container buttons' row under the World list (ContainerControls.lua:44-45: single-container view only)
function S.ccCount()
    local n = 0
    local c = S.wc()
    for _, z in ipairs((c and c._hitZones) or {}) do
        if type(z.id) == "string" and z.id:sub(1, 3) == "cc:" then n = n + 1 end
    end
    return n
end
-- the rows a list of inv shows (InventoryRenderer.lua:2368 liveCount: what the heading counts)
function S.shown(inv)
    local n = -1
    if inv then pcall(function() n = ZeD.InventoryRenderer.liveCount(inv, S.p) end) end
    return n
end
-- a window's place in the draw order (the later, the higher)
function S.zIdx(w)
    local n = -1
    local jo = w and w.javaObject or nil
    if not jo then return n end
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do if ui:get(i) == jo then n = i end end
    end)
    return n
end

-- ===================================================================== the drag, the pause
function S.dragOn()
    local c = S.k19.c or S.wc()
    local d = c and c._drag or nil
    local on = false
    if d and d.isActive then pcall(function() on = d:isActive() end) end
    return on and true or false
end
-- the drag let go with nothing dropped: the chip off, the list's capture and picks cleared (gallery_story_shots.lua
-- Z.drag(false)), the card follows the empty pick
function S.dragOff()
    local c = S.k19.c or S.wc()
    S.k19.c = nil
    if not c then return end
    pcall(function() if c._drag and (c._drag:isActive() or c._drag:isPending()) then c._drag:cancel() end end)
    pcall(function() c:setCapture(false) end)
    c._deferredSelect, c._dragSourceCol, c._dragSourceInv = nil, nil, nil
    local sel = c._selectedItems
    if type(sel) == "table" then for k in pairs(sel) do sel[k] = nil end end
    for _, cs in ipairs(c._colStates or {}) do
        if type(cs.selectedItems) == "table" then for k in pairs(cs.selectedItems) do cs.selectedItems[k] = nil end end
    end
    c._lastClickedItem = nil
    local w = S.WW()
    if w and w._updateDrawer then pcall(w._updateDrawer) end
end
-- paused as the game's own pause button pauses (zedqa_prelude.lua:25 ZEDQA_SPEED 0); false plays again at the speed found
function S.pause(on)
    if on then
        S.speedWas = getGameSpeed()
        if ZEDQA_SPEED then pcall(ZEDQA_SPEED, 0) else pcall(setGameSpeed, 0) end
        S.paused = true
    elseif S.paused then
        local sp = (S.speedWas and S.speedWas > 0) and S.speedWas or 1
        if ZEDQA_SPEED then pcall(ZEDQA_SPEED, sp) else pcall(setGameSpeed, sp) end
        S.paused = false
    end
end
-- the glass on both windows (ZeD_PausedLook.lua:172-236: PL._glass on the Character window, PL._wglass on the World one)
function S.veils()
    local PL = ZeD.PausedLook
    if not PL then return false end
    local g, w = PL._glass, PL._wglass
    local on = false
    pcall(function() on = g ~= nil and w ~= nil and g:isVisible() and w:isVisible() end)
    return on and true or false
end

-- ===================================================================== each picture's own put-back
function S.k10back()
    local K = S.k10
    S.mouseOff()
    S.unhold()
    for _, it in ipairs(K.foods or {}) do S.drop(it) end
    K.foods = {}
    if K.obj then S.removeObj(K.obj) end
    K.obj, K.inv = nil, nil
    -- (the strip's scroll back at its top, if it was wheeled for the picture)
    local w = S.WW()
    if w and (K.wheel or 0) > 0 then w._stripScrollOffset = 0 end
    K.wheel = nil
    S.dirty()
end
function S.k11back()
    local K = S.k11
    local lost = S.moveBackList(K.moved)
    K.moved = {}
    if K.hot then K.hotN, K.hotOf = S.hotBack(K.hot); K.hot = nil end
    if K.weapon then S.drop(K.weapon); K.weapon = nil end
    if K.gaveJacket then S.drop(K.gaveJacket); K.gaveJacket = nil end
    S.handsBack()
    return lost
end
function S.k19back()
    local K = S.k19
    S.dragOff()
    for _, it in ipairs(K.fill or {}) do S.drop(it) end
    K.fill = {}
    if K.rifle then S.drop(K.rifle); K.rifle = nil end
    if K.bag then S.drop(K.bag); K.bag = nil end
    if K.back then
        local it, loc = K.back.it, K.back.loc
        pcall(function() if it:getContainer() == nil then S.p:getInventory():AddItem(it) end end)
        pcall(function() S.p:setWornItem(loc, it) end)
        K.backOn = false
        pcall(function() K.backOn = S.p:getWornItem(loc) == it end)
        K.back = nil
    end
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
    if K.hot then K.hotN, K.hotOf = S.hotBack(K.hot); K.hot = nil end
    K.bagInv = nil
    -- (the Character window's strip back at its top, if it was wheeled for the picture)
    local cw = S.CW()
    if cw and (K.wheel or 0) > 0 then cw._stripScrollOffset = 0 end
    K.wheel, K.wheelAt = nil, nil
end

-- 19's school bag on his back, filled; the rifle in the crate. nil when staged, else why not
function S.wearSchoolbag()
    local K = S.k19
    K.hot = S.hotSnap()
    K.bag = S.giveFirst(S.SCHOOLBAGS)
    if not K.bag then return "no school bag could be given" end
    local loc = nil
    pcall(function() loc = K.bag:canBeEquipped() end)
    if loc == nil or loc == "" then return "the school bag has no place to be worn" end
    local there = nil
    pcall(function() there = S.p:getWornItem(loc) end)
    if there then
        -- the bag on his back set aside for the picture: off him and out of his inventory, whole, with what is in it
        pcall(function() S.p:removeWornItem(there, false) end)
        pcall(function() S.p:getInventory():Remove(there) end)
        K.back = { it = there, loc = loc }
    end
    pcall(function() S.p:setWornItem(loc, K.bag) end)
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
    local on = false
    pcall(function() on = S.p:getWornItem(loc) == K.bag end)
    if not on then return "the school bag could not be worn" end
    K.bagInv = nil
    pcall(function() K.bagInv = K.bag:getInventory() end)
    if not K.bagInv then return "the school bag has no inventory" end
    K.cap = 15
    pcall(function() K.cap = K.bagInv:getCapacity() end)
    pcall(function() if K.bagInv.getEffectiveCapacity then K.cap = K.bagInv:getEffectiveCapacity(S.p) end end)
    K.cap = tonumber(K.cap) or 15
    -- filled close to its capacity: each heavy thing goes in while there is more than a kilo of room, and comes out
    -- again if it went over
    K.fill = {}
    for _, ft in ipairs(S.FILL) do
        if K.cap - S.wt(K.bagInv) > 1.0 then
            local it = S.addTo(K.bagInv, ft)
            if it then
                if S.wt(K.bagInv) > K.cap then S.drop(it) else K.fill[#K.fill + 1] = it end
            end
        end
    end
    K.room = K.cap - S.wt(K.bagInv)
    K.rifle = S.giveFirst(S.RIFLES, S.crate)
    if not K.rifle then return "no rifle could be put in the crate" end
    K.rw = 0
    pcall(function() K.rw = K.rifle:getUnequippedWeight() end)
    K.rw = tonumber(K.rw) or 0
    K.fits = nil
    pcall(function() K.fits = K.bagInv:hasRoomFor(S.p, K.rifle) end)
    if K.rw <= K.room or K.fits == true then
        return string.format("the rifle (%.1f) fits the room left in the bag (%.1f of %.1f): no picture of a move that fails", K.rw, K.room, K.cap)
    end
    return nil
end
-- the school bag's picture on the Character window's container strip (ZeD_CharacterWindow.lua:4093 "cnt:<index>")
function S.bagZone()
    local cw = S.CW()
    local strip = cw and cw._containerStrip or nil
    local ci = S.ciOf(cw, S.k19.bagInv)
    if not (strip and ci) then return nil end
    local z = S.zone(strip, "cnt:" .. ci)
    if not z then return nil end
    return strip, z
end

-- ===================================================================== start
Q.step(5, function()
    S.start0()
    if getGameSpeed() ~= 1 then pcall(setGameSpeed, 1) end
    S.was.style = S.ctxOpt():getValue()
    S.was.h1, S.was.h2 = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    pcall(function() S.was.zoom = S.core:getZoom(S.pn) end)
    pcall(function() S.was.hp = S.p:getBodyDamage():getOverallBodyHealth() end)
    -- the mouse's input mode for every picture (a controller mode anchors a menu on the character); put back at the end
    S.lock("kbm")
    local c = S.P.smoke or S.P.centre
    if c then S.c = S.findPatch(c[1], c[2]) end
    S.openPair()
    Q.say("the patch's middle " .. (S.c and (S.c.x .. "," .. S.c.y) or "none") .. " (the smoking spot " .. (c and (c[1] .. "," .. c[2]) or "?")
        .. ") | Context menu setting " .. tostring(S.was.style) .. " (ZeD's default 1, Strip) | input lock found " .. tostring(S.lockWas)
        .. " | zoom found " .. tostring(S.was.zoom) .. " | load " .. ((GAL_UNLOAD and GAL_UNLOAD.line) and GAL_UNLOAD.line() or "?"))
end)
Q.zoomTo(1.0)
Q.waitFor(10, 600, function() return S.CW() ~= nil and S.WW() ~= nil and S.CWm.isOpen() and S.WWm.isOpen() end, function(ok)
    if not ok then Q.say("ERR the windows did not open") end
    pcall(function() S.was.snap = ZEDQA_LAYOUT_SNAP and ZEDQA_LAYOUT_SNAP() or nil end)
end)

-- ===================================================================== 07: the strip, its one balloon
Q.step(10, function()
    local K = S.k07
    if not S.c then S.skip(K.name, "no open patch near the smoking spot"); K.off = true; return end
    S.home("SE")
    S.openPair()
end)
S.settle(function() return not S.k07.off end)
Q.step(30, function()
    local K = S.k07
    if K.off then return end
    S.homeLayout()
    S.charTab("loot"); S.worldTab("loot")
    K.it = S.giveFirst(S.BEANS)
    if not K.it then S.skip(K.name, "no can of beans could be given"); K.off = true; return end
    S.seekPos = nil
    S.openStackOf(K.it)
    -- (the player's pointer is on the row he right-clicks: the Character window held in use, solid, as W15)
    S.holdWin(S.CW(), true)
    S.holdWin(S.WW(), false)
end)
Q.waitFor(10, 600, function() return S.k07.off or S.noColumns() end, function() end)
-- the windows off him, then the Character window a card's width in from the screen's left edge, still clear of him:
-- the card the right-click opens takes that room, and the list stays where it is under the strip
Q.still(10, function()
    local K = S.k07
    if K.off then return end
    S.clearChar()
    K.room = S.placeForCard()
    K.box0 = S.box(S.CW())
end)
-- (the window at rest in its new place: its right edge's anchor follows it, ZeD_CharacterWindow.lua:5219-5221)
Q.still(5, function() end)
Q.waitFor(5, 600, function() local K = S.k07; return K.off or S.seekShown(S.cc(), K.it) end, function(ok)
    local K = S.k07
    if K.off then return end
    local c = S.cc()
    local z = (ok and c) and S.zone(c, K.it) or nil
    if not z then S.skip(K.name, "the can's row never stood whole in the Character list's view"); K.off = true; return end
    -- where on the row (bxr_menus.lua:1041-1050 W15, kiss_deck.lua): the strip opens with its bottom T.px(6) above the
    -- click, so a click near the row's top lays it level on the row above; with no room above for its balloon it flips
    -- under the click (ZeD_ContextMenu.lua:1016-1047 _positionAssembly, the same test here), and then a click near the
    -- row's foot lays it on the row below. Either way the clicked row stays in sight
    local x, y = nil, nil
    pcall(function()
        local T = ZeD.T
        local k = T.ctx
        local stripH = k.cellH + k.drilledBorderTop + T.px(1)
        local top = c:getAbsoluteY() + z.y
        local pad, need, sh = T.px(8), T.px(160) + stripH + T.px(6), S.core:getScreenHeight()
        local lo, hi = top + 2, top + z.h - 2
        local yA = S.fl(math.max(lo, math.min(hi, top - z.h / 2 + stripH / 2 + T.px(6))))
        local yB = S.fl(math.max(lo, math.min(hi, top + z.h * 1.5 - stripH / 2 - T.px(6))))
        local flipA = (yA - pad) < need and (sh - yA - pad) > (yA - pad)
        local flipB = (yB - pad) < need and (sh - yB - pad) > (yB - pad)
        y = (flipA and flipB) and yB or yA
        x = S.fl(c:getAbsoluteX() + z.x + math.min(z.w / 2, T.px(110)))
        K.rowTop, K.rowH = top, z.h
    end)
    if not (x and y) then S.skip(K.name, "the row's place on the screen could not be read"); K.off = true; return end
    -- Context menu at ZeD's own default, the strip (Settings.lua:268-272: its first item, "default: the strip"), and no
    -- pinned actions, the default too (his own set aside for the picture)
    S.style(1)
    S.pinsAside()
    K.x, K.y, K.openMs = x, y, getTimestampMs()
    K.selWas = S.selNow()
    -- the right-click as a mouse player's lands: the list's own handlers at the row, the pointer the game reads there
    S.mouseOn(x, y)
    local lx, ly = x - c:getAbsoluteX(), y - c:getAbsoluteY()
    K.clicked = true
    local okM, e = pcall(function() c:onRightMouseDown(lx, ly); c:onRightMouseUp(lx, ly) end)
    if not okM then K.err = tostring(e) end
    K.asked = true
end)
-- the menu made: the pointer the game reads goes off the strip. A cell takes the selection only when that pointer
-- moves onto it (ZeD_ContextMenu.lua:807-835); off every cell, the lit one is the first (selected = 1 at open, :61)
Q.waitFor(1, 300, function() local K = S.k07; return K.off or not K.asked or K.err ~= nil or S.menuSettled() end, function()
    if S.k07.asked then S.mouseOn(-9000, -9000) end
end)
-- drawn: the strip laid out and its balloon up (ZeD_ContextMenu.lua:427-460, the balloon from the selected cell)
Q.waitFor(1, 180, function()
    local K = S.k07
    if K.off or not K.asked or K.err then return true end
    local m = S.menu()
    local lc = m and m._layoutCache or nil
    return lc ~= nil and (lc.stripW or 0) > 0 and (lc.balloonW or 0) > 0
end, function() end)
S.wait(400, function() return false end, function() end)
-- the windows at rest (the card's drawer done opening), no new Lua error, the menu still up
Q.still(2, function()
    local K = S.k07
    if K.off or not K.asked then return end
    local m = S.menu()
    if K.err or not m then
        local v, cc = S.vmenu(), S.cc()
        local rowSel = cc ~= nil and type(cc._selectedItems) == "table" and cc._selectedItems[K.it] == true
        S.skip(K.name, K.err and ("the right-click threw: " .. K.err) or ("ZeD's menu did not open after the row's right-click (the row selected "
            .. tostring(rowSel) .. ", the game's options " .. tostring(v and v.options and #v.options) .. ", ZeD's menu failed " .. tostring(v and v._zedFailed) .. ")"))
        return
    end
    if m.Type ~= "ZeD_ContextMenu" then S.skip(K.name, "the menu opened as " .. tostring(m.Type) .. ", not the strip"); return end
    local ctx = m._ctx or {}
    local items = ctx.items or {}
    local names = {}
    for i, d in ipairs(items) do if i <= 14 then names[#names + 1] = tostring(d.name) end end
    local lc = m._layoutCache or {}
    local cur = ctx.currentDef and tostring(ctx.currentDef.name) or "none"
    local lit = (ctx.selected == 1) and ("the first cell (\"" .. cur .. "\")") or ("cell " .. tostring(ctx.selected) .. " (\"" .. cur .. "\", NOTE not the first)")
    local x0, y0 = m:getX() + (lc.stripX or 0), m:getY() + (lc.stripY or 0)
    -- where the strip lies against the clicked row (its middle against the row's)
    local where = "?"
    if K.rowTop and K.rowH then
        local d = (y0 + (lc.stripH or 0) / 2) - (K.rowTop + K.rowH / 2)
        if d <= -K.rowH / 2 then where = "on the row above the clicked one"
        elseif d >= K.rowH / 2 then where = "on the row below the clicked one"
        else where = "NOTE over the clicked row" end
    end
    local cw, cc = S.CW(), S.cc()
    local rowSel = cc ~= nil and type(cc._selectedItems) == "table" and cc._selectedItems[K.it] == true
    local push = ((cw and cw._drawerCapPush) or 0) > 0
    S.shotOk(K.name, "ZeD's defaults for the picture: Context menu Strip (the setting was " .. tostring(S.was.style) .. ") and no pinned actions ("
        .. tostring(S.was.nPins or 0) .. " of his set aside); a mouse right-click on " .. S.nm(K.it) .. "'s row of the Character list at " .. tostring(K.x) .. ","
        .. tostring(K.y) .. " (the list's own right-click, the pointer the game reads on the row): the row selected " .. tostring(rowSel)
        .. ", its item card open in the drawer " .. tostring(S.cardOn(K.it)) .. " (a right-click on a row does both); the Character window "
        .. S.boxWord(K.box0) .. " before it" .. (K.room and "" or " (NOTE no room for the whole card on its left)") .. ", " .. S.boxWord(S.box(cw)) .. " with the card"
        .. (push and " (NOTE the card pinned it at the screen's left edge: the list moved under the strip)" or " (the card opened to its left, the list in place)")
        .. (G1.covers(cw) and ", NOTE it covers him" or "")
        .. "; the strip of " .. #items .. " cells of small pictures, no words on them (Molecules.lua:4273 drawContextStrip)"
        .. (ctx.truncating and " (more than fit: arrows at its ends)" or "") .. ", at " .. S.fl(x0) .. "," .. S.fl(y0) .. " " .. S.fl(lc.stripW) .. "x" .. S.fl(lc.stripH)
        .. (m._flipped and ", under the click (no room above it)" or ", above the click") .. ", " .. where
        .. (S.over(x0, y0, lc.stripW or 0, lc.stripH or 0) and ", NOTE over the character" or ", beside the character")
        .. "; lit: " .. lit .. ", the one balloon " .. (((lc.balloonW or 0) > 0) and ("naming it alone (" .. S.fl(lc.balloonW) .. "x" .. S.fl(lc.balloonH) .. ")") or "NOT up")
        .. "; the cells in order: " .. table.concat(names, ", ") .. "; the Character window held in use (solid), the World window not; the pointer the game reads"
        .. " moved off the strip after the click (no cell hovered)", true)
end)
Q.step(5, function()
    local K = S.k07
    S.closeMenu()
    S.cardShut()
    S.style(S.was.style)
    S.pinsBack()
    S.unhold()
    S.stacksBack()
    S.scrollTop()
    if K.it then S.drop(K.it); K.it = nil end
end)

-- ===================================================================== 10: a click on a container's picture adds a column
Q.step(10, function()
    local K = S.k10
    S.closeMenu()
    K.spot = S.freezerSpot()
    if not K.spot then S.skip(K.name, "no floor square in the store with room for a fridge against the wall behind it and clear floor in front of him"); K.off = true; return end
    G1.tp(K.spot.q, "SE")
end)
S.settle(function() return not S.k10.off end)
Q.step(20, function()
    local K = S.k10
    if K.off then return end
    local sq = K.spot.f
    if not S.sqFree(sq) then S.skip(K.name, "the fridge's square is no longer free"); K.off = true; return end
    K.obj, K.inv, K.sprite = S.placeTile(sq, S.FRIDGES[K.spot.side] or S.FRIDGES.N, "fridge")
    if not K.inv then S.skip(K.name, "no fridge tile could be placed"); K.off = true; return end
    K.foods = {}
    for _, ft in ipairs(S.FRIDGE_FOODS) do
        local it = S.addTo(K.inv, ft)
        if it then K.foods[#K.foods + 1] = it end
    end
    S.openPair()
    S.homeLayout()
    S.charTab("loot"); S.worldTab("loot")
    S.mouseOn(-9000, -9000)
    -- (the player's pointer is on the World window's strip for the click: that window in use, the other not)
    S.holdWin(S.WW(), true)
    S.holdWin(S.CW(), false)
    S.dirty()
    Q.say(K.name .. ": in the store at " .. K.spot.q[1] .. "," .. K.spot.q[2] .. ", " .. tostring(K.sprite) .. " placed on his "
        .. ((K.spot.side == "N") and "north" or "west") .. " side " .. ((K.spot.pass == 1) and "against a wall of its own" or "at the room's end (NOTE no wall of its own found)")
        .. ((K.spot.strict == 1) and ", the floor in front of him bare" or " (NOTE things on the floor in front of him)") .. ", " .. #K.foods .. " foods in its fridge")
end)
Q.waitFor(10, 600, function() return S.k10.off or S.noColumns() end, function() end)
Q.waitFor(10, 900, function() local K = S.k10; return K.off or S.ciOf(S.WW(), K.inv) ~= nil end, function(ok)
    local K = S.k10
    if K.off then return end
    if not ok then S.skip(K.name, "the World window does not list the fridge"); K.off = true; return end
    -- the World window shows the Floor (ZeD_WorldWindow.lua:6332 selectContainer: the floor active and shown)
    local fl = S.floorInv()
    if fl then pcall(S.WWm.selectContainer, fl, 60, S.pn) end
end)
Q.waitFor(5, 300, function() return S.k10.off or S.worldOnFloor() end, function(ok)
    if not S.k10.off and not ok then Q.say("note: " .. S.k10.name .. ": the World window is not on the Floor before the click") end
end)
-- the Character window off the character; the World window stays where it opened: it widens from there
Q.still(10, function() if not S.k10.off then G1.clear(Q, S.CW(), "left", "the Character window") end end)
-- the fridge's picture in the strip's view: a player wheels the strip down to one out of view (the strip's own
-- onMouseWheel, ZeD_WorldWindow.lua:4071-4078, one button a notch), at most a dozen notches
Q.waitFor(2, 120, function()
    local K = S.k10
    if K.off then return true end
    local ww = S.WW()
    local strip = ww and ww._containerStrip or nil
    local ci = S.ciOf(ww, K.inv)
    local z = (strip and ci) and S.zone(strip, ci) or nil
    if not z then return false end
    if S.inView(ww, z) then return true end
    K.wheel = (K.wheel or 0) + 1
    if K.wheel > 12 then return true end
    local L = ww._stripLay or {}
    pcall(strip.onMouseWheel, strip, (z.y < (L.listY or 0)) and -1 or 1)
    return false
end, function()
    local K = S.k10
    if K.off or (K.wheel or 0) == 0 then return end
    local ww = S.WW()
    local strip = ww and ww._containerStrip or nil
    local ci = S.ciOf(ww, K.inv)
    local seen = S.inView(ww, (strip and ci) and S.zone(strip, ci) or nil)
    Q.say(K.name .. ": the strip wheeled " .. K.wheel .. " notch(es) to bring the fridge's picture into view (in view " .. tostring(seen) .. ")")
end)
Q.still(6, function()
    local K = S.k10
    if K.off then return end
    local ww = S.WW()
    local strip = ww and ww._containerStrip or nil
    local ci = S.ciOf(ww, K.inv)
    local z = (strip and ci) and S.zone(strip, ci) or nil
    if not z then S.skip(K.name, "the fridge's picture is not on the World window's strip"); K.off = true; return end
    if not S.inView(ww, z) then S.skip(K.name, "the fridge's picture is out of the strip's view"); K.off = true; return end
    K.w0, K.cc0, K.floor0 = ww:getWidth(), S.ccCount(), S.worldOnFloor()
    -- the click, as a mouse press lands: the strip's own onMouseDown at the picture's hit zone (ZeD_WorldWindow.lua:4003,
    -- :4025-4031: on Loot a container's press is mcToggleWorldContainer, :2480, which adds its column beside the
    -- Floor's and widens the window, snapWorldColumns :2462)
    local okC = pcall(strip.onMouseDown, strip, z.x + S.fl(z.w / 2), z.y + S.fl(z.h / 2))
    K.clicked = okC
    if not okC then S.skip(K.name, "the press on the fridge's picture threw") end
end)
-- the windows still after the widening, then off the character if the wider window covers him
Q.still(10, function() if S.k10.clicked then S.clearChar() end end)
Q.still(6, function()
    local K = S.k10
    if not K.clicked then return end
    local ww, c = S.WW(), S.wc()
    local cols = {}
    for _, cs in ipairs((c and c._colStates) or {}) do
        cols[#cols + 1] = S.invName(ww, cs.inventory) .. " " .. S.fl(cs.renderW) .. " px"
    end
    local mc = (ww and ww._mcSelected) or {}
    local fridgeCol = #mc == 1 and S.ciOf(ww, K.inv) == mc[1]
    local both = fridgeCol and ww._mainVisible == true
    S.shotOk(K.name, "inside the store, " .. tostring(K.sprite) .. " placed against the wall behind him, " .. #(K.foods or {}) .. " foods in its fridge; "
        .. "the World window on Loot " .. (K.floor0 and "showing the Floor" or "(NOTE not on the Floor)") .. " was " .. S.fl(K.w0) .. " px wide; a plain click on the fridge's "
        .. "picture on its container strip: now " .. S.fl(ww and ww:getWidth()) .. " px wide, " .. #cols .. " columns side by side (" .. table.concat(cols, ", ") .. ")"
        .. (both and ", the fridge and the Floor" or ", NOTE not the fridge and the Floor")
        .. "; the container buttons' row (Take all) under the list before the click: " .. tostring(K.cc0) .. " buttons, under the columns now: " .. S.ccCount()
        .. "; the World window held in use (the click was on it), the Character window not, the pointer the game reads off the windows")
end)
Q.step(5, function()
    local K = S.k10
    if not K.clicked then return end
    -- the fridge's picture again: its column closes, the player's way back
    local ww = S.WW()
    local strip = ww and ww._containerStrip or nil
    local ci = S.ciOf(ww, K.inv)
    local z = (strip and ci) and S.zone(strip, ci) or nil
    local inMc = false
    for _, j in ipairs((ww and ww._mcSelected) or {}) do if j == ci then inMc = true end end
    if z and inMc then pcall(strip.onMouseDown, strip, z.x + S.fl(z.w / 2), z.y + S.fl(z.h / 2)) end
end)
Q.waitFor(5, 300, function() return S.noColumns() end, function() end)
Q.step(10, function() S.k10back() end)

-- ===================================================================== 11: what he wears and holds is not in his list
Q.step(10, function()
    local K = S.k11
    S.closeMenu()
    if not S.c then S.skip(K.name, "no open patch near the smoking spot"); K.off = true; return end
    S.home("SE")
    if not S.crateHere() then S.skip(K.name, "no crate could be placed beside him on the patch"); K.off = true; return end
end)
S.settle(function() return not S.k11.off end)
Q.step(10, function()
    local K = S.k11
    if K.off then return end
    -- dressed: a jacket given and worn only when he wears none (the story kit wears one)
    if not S.wornHas("Jacket") then
        K.gaveJacket = S.giveFirst(S.JACKETS)
        if K.gaveJacket and not S.wearIt(K.gaveJacket) then S.drop(K.gaveJacket); K.gaveJacket = nil end
    end
    -- the weapon held as the game holds it: the crowbar (and the bat) is a two-handed weapon (TwoHandWeapon = true in
    -- the game's weapon.txt), which the game's equip puts in both hands (ISEquipWeaponAction with twoHands)
    K.weapon = S.giveFirst(S.WEAPONS)
    if K.weapon then
        pcall(function() S.p:setPrimaryHandItem(K.weapon) end)
        local two = false
        pcall(function() two = K.weapon:isTwoHandWeapon() and true or false end)
        if two then pcall(function() S.p:setSecondaryHandItem(K.weapon) end) end
        K.two = two
    end
    -- every loose thing of his main inventory into the crate. The belt's, holster's and back slot's things are rows of
    -- the list (InventoryRenderer.lua:1707-1710 draws their BELT tag; only worn and held things leave it, :2088-2105),
    -- so they come off their slots first (ISHotbar:removeItem without the animation)
    K.hot = S.hotSnap()
    local loose = S.looseThings()
    local hb = S.hb()
    K.n, K.att, K.of = 0, 0, #loose
    for _, it in ipairs(loose) do
        local slot = -1
        pcall(function() slot = it:getAttachedSlot() end)
        if slot and slot > -1 and hb then pcall(function() hb:removeItem(it, false) end); K.att = K.att + 1 end
        if S.moveTo(it, S.crate, K.moved) then K.n = K.n + 1 end
    end
    S.openPair()
    S.homeLayout()
    S.charTab("loot"); S.worldTab("loot")
    -- (the World window on the Floor, where it opens: the crate's list, his own things in it for the picture, is not
    -- what a player there would be looking at)
    local fl = S.floorInv()
    if fl then pcall(S.WWm.selectContainer, fl, 60, S.pn) end
    S.mouseOn(-9000, -9000)
    S.holdWin(S.CW(), false); S.holdWin(S.WW(), false)
    K.on = true
end)
Q.waitFor(10, 600, function() return not S.k11.on or S.noColumns() end, function() end)
Q.waitFor(10, 600, function() return not S.k11.on or S.shown(S.p:getInventory()) == 0 end, function(ok)
    if S.k11.on and not ok then Q.say("note: " .. S.k11.name .. ": his main inventory still shows " .. S.shown(S.p:getInventory()) .. " rows") end
end)
Q.still(10, function() if S.k11.on then S.clearChar() end end)
Q.still(6, function()
    local K = S.k11
    if not K.on then return end
    local n = S.shown(S.p:getInventory())
    local cw, cc = S.CW(), S.cc()
    if n ~= 0 then S.skip(K.name, "his main inventory still shows " .. n .. " rows after the move (" .. K.n .. " of " .. K.of .. " moved)"); return end
    -- (the list the picture is about: his main inventory's, on the first tab, Loot)
    if not (cw and cw._activeTab == "loot" and cc and cc._inventory == S.p:getInventory()) then
        S.skip(K.name, "the Character window is not on Loot with his main inventory's list (tab " .. tostring(cw and cw._activeTab) .. ")"); return
    end
    local held = "NOTE no weapon could be given"
    if K.weapon then held = S.nm(K.weapon) .. (K.two and " held in both hands (a two-handed weapon, as the game equips it)" or " in his main hand") end
    local wc = S.wc()
    local wInv = wc and wc._inventory or nil
    S.shotOk(K.name, "on the open patch, dressed (" .. S.wornNames() .. ")" .. (K.gaveJacket and " (the jacket given for the picture)" or "")
        .. ", " .. held .. "; every loose thing of his main inventory ("
        .. K.n .. " of " .. K.of .. ", " .. K.att .. " of them off the belt, holster and back slots) moved into the crate beside him; the Character window on its first tab ("
        .. tostring(cw._activeTab) .. "): its list reads \"" .. tostring(ZeD.tr("UI_ZeD_Inv_Empty")) .. "\" (ZeD counts " .. n .. " rows) with all he wears and holds"
        .. " left out of it; the World window on " .. S.invName(S.WW(), wInv) .. "; both windows not in use, the pointer the game reads off them")
end)
Q.step(5, function()
    local K = S.k11
    S.mouseOff()
    S.unhold()
    if K.off then return end
    local lost = S.k11back()
    Q.say(K.name .. ": put back: his things back in his main inventory (" .. tostring(lost) .. " not back), on their slots again "
        .. tostring(K.hotN) .. " of " .. tostring(K.hotOf))
end)

-- ===================================================================== 13: the World window opens on the Floor
Q.step(10, function()
    local K = S.k13
    S.closeMenu()
    if not S.stageCounter() then S.skip(K.name, (S.cnt and S.cnt.why) or "no counter to stand at"); K.off = true; return end
    local C = S.cnt
    G1.tp({ C.st.x, C.st.y }, C.face)
    Q.say(K.name .. ": " .. C.how .. " at " .. C.x .. "," .. C.y .. ", he stands at " .. C.st.x .. "," .. C.st.y .. " facing " .. C.face
        .. (C.st.bare and ", the floor round him bare" or ", NOTE things lie on the floor round him")
        .. ((C.st.cam == false) and ", NOTE the counter stands between him and the camera (no free square east or south of it)" or "")
        .. "; its own things set aside " .. #C.own .. ", foods put in " .. #C.foods)
end)
S.settle(function() return not S.k13.off end)
Q.step(10, function()
    if S.k13.off then return end
    S.openPair()
    S.charTab("loot"); S.worldTab("loot")
    S.dirty()
end)
Q.waitFor(10, 900, function() return S.k13.off or S.ciOf(S.WW(), S.cnt.inv) ~= nil end, function(ok)
    local K = S.k13
    if K.off then return end
    if not ok then S.skip(K.name, "the World window does not list the counter"); K.off = true; return end
    -- the World window's last container made the Floor (ZeD_WorldWindow.lua:6332 selectContainer)
    local fl = S.floorInv()
    if fl then pcall(S.WWm.selectContainer, fl, 60, S.pn) end
end)
Q.waitFor(5, 300, function() return S.k13.off or S.worldOnFloor() end, function(ok) S.k13.lastFloor = ok end)
-- both windows closed, the pair's own close (hfr_common.lua S.closePair)
Q.step(10, function() if not S.k13.off then S.closePair() end end)
Q.waitFor(5, 300, function() return S.k13.off or not (S.CWm.isOpen() or S.WWm.isOpen()) end, function(ok)
    local K = S.k13
    if K.off then return end
    if not ok then S.skip(K.name, "the windows did not close"); K.off = true end
end)
Q.step(30, function()
    local K = S.k13
    if K.off then return end
    S.mouseOn(-9000, -9000)
    -- opened as the inventory key opens them: the key's own handler with the key bound to Toggle Inventory
    -- (ZeD_CharacterWindow.lua:7660 _onKeyPressed, kept on the module for test scripts; it calls toggleBothPaired, :7511)
    local key = nil
    pcall(function() key = getCore():getKey("Toggle Inventory") end)
    if type(key) == "number" and key > 0 and S.CWm._onKeyPressed then
        K.how = "the inventory key's own handler (key " .. tostring(key) .. ")"
        pcall(S.CWm._onKeyPressed, key)
    else
        K.how = "toggleBothPaired (the key's handler was not found)"
        pcall(S.CWm.toggleBothPaired, S.pn)
    end
    K.on = true
end)
Q.waitFor(10, 900, function()
    local K = S.k13
    if not K.on then return true end
    return S.CWm.isOpen() and S.WWm.isOpen() and S.ciOf(S.WW(), S.cnt.inv) ~= nil
end, function(ok)
    local K = S.k13
    if K.on and not ok then S.skip(K.name, "after the key both windows were not open with the counter on the World strip"); K.on = false end
end)
Q.still(10, function()
    if not S.k13.on then return end
    S.holdWin(S.CW(), false); S.holdWin(S.WW(), false)
    S.clearChar()
end)
Q.still(6, function()
    local K = S.k13
    if not K.on then return end
    local ww, c = S.WW(), S.wc()
    local fl = S.floorInv()
    local ci = S.ciOf(ww, S.cnt.inv)
    if not (S.worldOnFloor() and c and c._inventory == fl) then
        S.skip(K.name, "the World window opened on " .. S.invName(ww, c and c._inventory or nil) .. ", not the Floor"); return
    end
    local n = S.shown(fl)
    local strip = ww and ww._containerStrip or nil
    local seen = S.inView(ww, (strip and ci) and S.zone(strip, ci) or nil)
    S.shotOk(K.name, "he faces " .. S.cnt.how .. " holding " .. #S.cnt.foods .. " foods put in it; the World window's last container made the Floor ("
        .. tostring(K.lastFloor) .. "), both windows closed, then opened with " .. tostring(K.how) .. ": the World window on the Floor, its list "
        .. ((n == 0) and ("reading \"" .. tostring(ZeD.tr("UI_ZeD_Inv_Empty")) .. "\"") or ("NOTE with " .. n .. " things lying round him"))
        .. "; the counter's picture on the strip (" .. S.invName(ww, S.cnt.inv) .. ") " .. (S.isLit(ww, ci) and "NOTE lit" or "unlit")
        .. (seen and ", in view" or ", NOTE scrolled out of the strip's view")
        .. ((S.cnt.st.cam == false) and "; NOTE the counter stands between him and the camera" or "")
        .. "; both windows not in use, the pointer the game reads off them")
end)
Q.step(5, function() S.mouseOff(); S.unhold() end)

-- ===================================================================== 19: a move into a full bag
Q.step(10, function()
    local K = S.k19
    S.closeMenu()
    if not S.c then S.skip(K.name, "no open patch near the smoking spot"); K.off = true; return end
    S.home("SE")
    if not S.crateHere() then S.skip(K.name, "no crate could be placed beside him on the patch"); K.off = true; return end
end)
S.settle(function() return not S.k19.off end)
Q.step(10, function()
    local K = S.k19
    if K.off then return end
    local why = S.wearSchoolbag()
    if why then S.skip(K.name, why); K.off = true; S.k19back(); return end
    S.openPair()
    S.homeLayout()
    S.charTab("loot"); S.worldTab("loot")
    S.dirty()
    Q.say(K.name .. ": " .. S.nm(K.bag) .. " worn" .. (K.back and (", " .. S.nm(K.back.it) .. " set aside") or "") .. ", filled "
        .. string.format("%.1f of %.1f (room %.1f)", S.wt(K.bagInv), K.cap, K.room) .. " with " .. #K.fill .. " things; " .. S.nm(K.rifle)
        .. string.format(" (%.1f)", K.rw) .. " in the crate")
end)
Q.waitFor(10, 600, function() return S.k19.off or S.noColumns() end, function() end)
Q.waitFor(10, 900, function()
    local K = S.k19
    if K.off then return true end
    if S.ciOf(S.WW(), S.crate) == nil then return false end
    local cw = S.CW()
    local strip, bz = S.bagZone()
    if strip and bz and S.inView(cw, bz) then return true end
    -- the bag listed but its picture out of the strip's view: a player wheels the strip down to it (the strip's own
    -- onMouseWheel, ZeD_CharacterWindow.lua:6356-6363, one button a notch), at most a dozen notches
    if cw and cw._containerStrip and S.ciOf(cw, K.bagInv) and (K.wheel or 0) < 12 then
        K.wheelAt = (K.wheelAt or 0) + 1
        if K.wheelAt >= 6 then
            K.wheelAt = 0
            K.wheel = (K.wheel or 0) + 1
            pcall(cw._containerStrip.onMouseWheel, cw._containerStrip, 1)
        end
    end
    return false
end, function(ok)
    local K = S.k19
    if K.off then return end
    if not ok then
        S.skip(K.name, "the crate is not on the World window's strip or the school bag not on the Character window's"); K.off = true; S.k19back(); return
    end
    pcall(S.WWm.selectContainer, S.crate, 60, S.pn)
end)
Q.waitFor(10, 600, function()
    local K = S.k19
    if K.off then return true end
    local c = S.wc()
    return c ~= nil and c._inventory == S.crate and S.zone(c, K.rifle) ~= nil
end, function(ok)
    local K = S.k19
    if K.off then return end
    if not ok then S.skip(K.name, "the rifle's row is not in the World list"); K.off = true; S.k19back() end
end)
Q.still(10, function() if not S.k19.off then S.clearChar() end end)
Q.step(5, function()
    local K = S.k19
    if K.off then return end
    local ww, cw, c = S.WW(), S.CW(), S.wc()
    local rz = c and S.zone(c, K.rifle) or nil
    local strip, bz = S.bagZone()
    if not (ww and cw and rz and strip and bz) then
        S.skip(K.name, "the rifle's row or the school bag's picture lost its place before the drag"); K.off = true; S.k19back(); return
    end
    local lx, ly = rz.x + S.fl(rz.w / 2), rz.y + S.fl(rz.h / 2)
    K.rx, K.ry = S.fl(c:getAbsoluteX() + lx), S.fl(c:getAbsoluteY() + ly)
    K.bx, K.by = S.fl(strip:getAbsoluteX() + bz.x + bz.w / 2), S.fl(strip:getAbsoluteY() + bz.y + bz.h / 2)
    K.c = c
    -- the press on the rifle's row with the pointer the game reads on the row: the list takes the drag's start from
    -- getMouseX / getMouseY (ZeD_WorldWindow.lua:5749 onMouseDown, :5897); no double-click memory left
    -- (InventoryRenderer.lua:495-503); the press brings the World window to the top, QA's model of a click
    -- (zedqa_break_c1c2.lua:87; gallery_story_shots.lua:327 Z.drag does the same for its drag)
    S.mouseOn(K.rx, K.ry)
    c._zedLastClick = nil
    pcall(function() ww:bringToTop() end)
    local okD = pcall(c.onMouseDown, c, lx, ly)
    -- out past the threshold to the school bag's picture: onMouseMove starts the drag (checkThreshold, capture, the card
    -- hidden, :6110-6136) and onMouseMoveOutside keeps the chip at the pointer (:6138-6152); the chip is drawn by the
    -- World window at that pointer (:5583-5586, Molecules.lua:1405-1464 drawGhost: the icon and the weight)
    S.mouseOn(K.bx, K.by)
    local okM = pcall(c.onMouseMove, c, K.bx - K.rx, K.by - K.ry)
    pcall(c.onMouseMoveOutside, c, 0, 0)
    -- the player's pointer is on the Character window's strip: that window in use (solid), the World one not
    S.holdWin(cw, true); S.holdWin(ww, false)
    K.pressed = okD and okM
    if not K.pressed then S.skip(K.name, "the press or the move on the World list threw") end
end)
Q.waitFor(1, 120, function() local K = S.k19; return K.off or not K.pressed or S.dragOn() end, function(ok)
    local K = S.k19
    if K.off or not K.pressed then return end
    if not ok then S.skip(K.name, "the drag did not start"); K.pressed = false end
end)
Q.still(6, function() end)
Q.step(2, function()
    local K = S.k19
    if K.off or not K.pressed then return end
    local c = K.c
    local d = c and c._drag or nil
    if not (d and S.dragOn()) then S.skip(K.name, "the drag ended before the picture"); return end
    local cw, ww = S.CW(), S.WW()
    local zc, zw = S.zIdx(cw), S.zIdx(ww)
    local at = S.fl(d.ghostX) .. "," .. S.fl(d.ghostY)
    S.shotOk(K.name, "on the open patch, " .. S.nm(K.bag) .. " worn on his back" .. (K.back and (" (" .. S.nm(K.back.it) .. " set aside for the picture)") or "")
        .. ", filled to " .. string.format("%.1f of %.1f", S.wt(K.bagInv), K.cap) .. " with " .. #K.fill .. " heavy things given (room left " .. string.format("%.1f", K.room) .. ")"
        .. "; the crate beside him holds " .. S.nm(K.rifle) .. " (" .. string.format("%.1f", K.rw) .. "; room for it in the bag: " .. tostring(K.fits) .. ")"
        .. "; ZeD's own drag of it from the crate's row, held over the school bag's picture on the Character window's container strip (the pointer the game reads at "
        .. K.bx .. "," .. K.by .. ", the chip's corner at " .. at .. "): the chip shows " .. S.nm(d.ghostItem) .. " and \"" .. string.format("%.1f", K.rw) .. "\""
        .. "; the bag's button under the pointer (its hover wash, its help words \"" .. tostring(ZeD.tr("UI_ZeD_CW_BagHelp", S.invName(cw, K.bagInv)))
        .. "\", ZeD_CharacterWindow.lua:4039-4054)"
        .. "; nothing warns that it will not fit (ZeD draws no room test during a drag)"
        .. "; the World window " .. ((zw > zc) and "on top (the press brought it up)" or "NOTE under the Character window") .. ", the Character window held in use")
end)
-- the drag let go with nothing dropped, and the pointer the game reads its own again: the step after the picture
Q.step(5, function() S.dragOff(); S.mouseOff(); S.unhold() end)
Q.step(10, function()
    local K = S.k19
    if not K.bag and not K.back then return end
    S.k19back()
    Q.say(K.name .. ": put back: the school bag and what filled it gone, the rifle gone, the bag he wore on his back again "
        .. tostring(K.backOn) .. ", on their slots " .. tostring(K.hotN) .. " of " .. tostring(K.hotOf))
end)

-- ===================================================================== 41: paused, both lists behind the veil
Q.step(10, function()
    local K = S.k41
    S.closeMenu()
    if not S.stageCounter() then S.skip(K.name, (S.cnt and S.cnt.why) or "no counter to stand at"); K.off = true; return end
    G1.tp({ S.cnt.st.x, S.cnt.st.y }, S.cnt.face)
end)
S.settle(function() return not S.k41.off end)
Q.step(10, function()
    if S.k41.off then return end
    S.openPair()
    S.homeLayout()
    S.charTab("loot"); S.worldTab("loot")
    S.dirty()
end)
Q.waitFor(10, 600, function() return S.k41.off or S.noColumns() end, function() end)
Q.waitFor(10, 900, function() return S.k41.off or S.ciOf(S.WW(), S.cnt.inv) ~= nil end, function(ok)
    local K = S.k41
    if K.off then return end
    if not ok then S.skip(K.name, "the World window does not list the counter"); K.off = true; return end
    pcall(S.WWm.selectContainer, S.cnt.inv, 60, S.pn)
end)
Q.waitFor(5, 300, function() local c = S.wc(); return S.k41.off or (c ~= nil and c._inventory == S.cnt.inv) end, function(ok)
    local K = S.k41
    if K.off then return end
    if not ok then S.skip(K.name, "the World list does not show the counter"); K.off = true end
end)
Q.still(10, function()
    if S.k41.off then return end
    S.mouseOn(-9000, -9000)
    S.holdWin(S.CW(), false); S.holdWin(S.WW(), false)
    S.clearChar()
end)
Q.step(5, function() if not S.k41.off then S.pause(true) end end)
Q.waitFor(2, 600, function() return S.k41.off or S.veils() end, function(ok)
    local K = S.k41
    if K.off then return end
    if not ok then S.skip(K.name, "paused (speed " .. tostring(getGameSpeed()) .. "), the veil is not on both windows"); K.off = true end
end)
S.wait(600, function() return false end, function() end)
Q.step(2, function()
    local K = S.k41
    if K.off then return end
    S.shotOk(K.name, "at " .. S.cnt.how .. " holding " .. #S.cnt.foods .. " foods, both windows open on their lists (the Character window: his own things; the World window: "
        .. S.invName(S.WW(), S.cnt.inv) .. "); the game paused (speed " .. tostring(getGameSpeed()) .. ", ZEDQA_SPEED 0 as the game's own pause button)"
        .. ": the veil over both lists (ZeD_PausedLook.lua:173-236, the glass on each window), its line \"" .. tostring(ZeD.tr("UI_ZeD_Char_PausedLook"))
        .. "\"; whatever the game itself draws while paused is left as it draws it"
        .. ((S.cnt.st.cam == false) and "; NOTE the counter stands between him and the camera" or "")
        .. "; both windows not in use, the pointer the game reads off them")
end)
Q.step(5, function() S.pause(false); S.mouseOff(); S.unhold() end)
Q.step(10, function() S.counterBack() end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    pcall(S.dragOff)
    S.closeMenu()
    pcall(S.cardShut)
    S.mouseOff()
    S.unhold()
    S.pause(false)
    S.style(S.was.style)
    S.pinsBack()
    S.lock(false)
    pcall(S.k19back)
    pcall(S.k11back)
    pcall(S.k10back)
    pcall(S.counterBack)
    pcall(S.crateBack)
    S.removeAll()
    S.stacksBack()
    S.scrollTop()
    S.takeMade()
    S.handsBack()
    -- out of any car (none is touched here; a car he sat in would be the story's)
    pcall(function()
        local v = S.p:getVehicle()
        if v then v:exit(S.p); triggerEvent("OnExitVehicle", S.p) end
    end)
    G1.glassesBack(Q)
end)
Q.waitFor(5, 300, function() return S.noColumns() end, function() end)
S.zoomDyn(function() return S.was.zoom end)
Q.step(20, function()
    S.openPair()
    S.charTab("loot"); S.worldTab("loot")
    if ZEDQA_LAYOUT_BACK and S.was.snap then pcall(ZEDQA_LAYOUT_BACK, S.was.snap, "kssl") end
    local hurt = false
    pcall(function() hurt = S.p:getBodyDamage():getOverallBodyHealth() < (S.was.hp or 100) - 0.01 end)
    if hurt then pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end) end
    if S.P.stock then G1.tp(S.P.stock, "SE") end
    S.back0()
end)
Q.step(30, function()
    if not S.was.pairOpen then S.closePair() end
    pcall(function() Mouse.setCursorVisible(true) end)
    Events.OnPreUIDraw.Remove(S.errWatch)
    local mode = "?"
    if S.Det and S.Det.getMode then pcall(function() mode = tostring(S.Det.getMode(S.pn)) end) end
    local car = S.p:getVehicle() ~= nil
    local pins = -1
    pcall(function() pins = S.count(S.p:getModData().ZeD_PinnedContextIds) end)
    Q.say("put back: things given taken away, his own things back where they were, placed objects still standing " .. S.standing()
        .. ", Context menu setting " .. tostring(S.ctxOpt():getValue()) .. " (found " .. tostring(S.was.style) .. "), pinned actions " .. tostring(pins)
        .. " (found " .. tostring(S.was.nPins or pins) .. "), input lock as found ("
        .. tostring(S.lockWas) .. "; ZeD reads " .. mode .. "), game speed " .. tostring(getGameSpeed()) .. ", zoom " .. tostring(S.zoom())
        .. " (found " .. tostring(S.was.zoom) .. "), mouse swap " .. tostring(S.mouseSwapped == true) .. ", windows held " .. #S.held
        .. ", alive " .. tostring(not S.p:isDead()) .. ", in a car " .. tostring(car)
        .. "; pictures taken: " .. ((#S.pic > 0) and table.concat(S.pic, ", ") or "none"))
end)
Q.start()
