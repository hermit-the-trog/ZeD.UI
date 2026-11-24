-- ZeDUI/tools/qa/rt_cards.lua  (Nov 18 2026, QA): the release test's item cards, object cards and stations
-- (ZeDUI/qa/RELEASE_TEST.md, the row "rt_cards.lua"). Built on rt_kit.lua (run it first); grep "ZEDQA rt_cards".
--
-- ITEM CARDS (ItemCard.lua, ItemCardOrganism.lua, ItemFactsPanel.lua, ItemActionHooks.lua). An apple, a baseball bat,
-- a book and a pencil are given to the main inventory (their stacks opened so each has its own row).
--   mouse   a click on the bat's row (the list's own onMouseDown / onMouseUp) opens its card in the drawer; the card is
--           220 or 480 wide; its top facts show the bat's weight ("n.n kg") and its facts panel its condition
--           ("cond / max"), both read from the card's own model (what it draws)
--   pad     ZeD's input locked to the controller, the Character window holding the pad (FocusManager), the focus on
--           the apple's row and A tapped (Focus.qaButton + dispatchJoypadDown): the apple's card opens
--   verbs   on the card's action strip, through the pad: Eat (A held: the game's ISEatFoodAction is queued, then
--           stopped), Read on the book (ISReadABook queued, then stopped), Equip on the bat (the bat in the hand),
--           Drop on the pencil (it leaves the inventory). Each is the game's own action, queued by ZeD's card.
-- OBJECT CARDS (ObjectCards.lua, ObjectCard*.lua), each beside the character, each opened the game's way:
--   generator  the game's Info (ISWorldObjectContextMenu.onInfoGenerator, hooked): fuel, condition, Off
--   fire       a campfire's Info (ISCampingMenu.onDisplayInfo, hooked): no fuel, not lit, Out
--   laundry    a washer's container row in the Loot pane: its gears button (ContainerControls) opens the card: Off
--   fridge     ZeD has no card of its own for it: the fridge is a container in the World window's Loot pane; it is
--              listed, it opens in the pane and its contents show
--   stove      the game's stove settings (ISOvenUITimedAction, hooked): the face pops out (faces on) or the Craft tab
--              binds the stove (faces off); the station's state words match the stove's power and switch
-- STATIONS (Stations.lua): a Primitive Kiln built beside the character (the game's build code with the build cheat);
-- the game's station option (ISEntityUI.OpenWindow, hooked) binds it in the World window's Craft tab, in use by you.
-- StationGeneral (a mod's machine) is a SKIP: no mod station is on the release-test save.
-- Every surface is measured with RT.bounds. Put back: the cards closed, the actions stopped, the pad let go and the
-- input mode unlocked, the stacks and the list's scroll as they were, the hands as they were, everything placed or
-- built taken away, the things given taken back (the dropped pencil off the floor), both windows on Loot.
-- (Nov 23 2026, QA: the card's plug-in points (Build's fix/plugins) keep the Lists mark's rect in card._markRects.lists
-- in place of card._listsRect; H.listsRect reads whichever this build has, so the Lite check runs on both.)
-- (Nov 23 2026, QA: the Loadouts split (Build's try/split) moves the Loadouts switch to the add-on ZeD-GUI: Loadouts,
-- ZeDLoadouts.loadoutsOption; H.loadOpt() reads the add-on's where it is loaded, else ZeD.Settings' from before the
-- split. With neither (ZeD alone after the split) the Lists mark is not ZeD's: its checks are a SKIP.)

if not RT then
    print("ZEDQA rt_cards ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA rt_cards VERDICT FAIL 1")
    print("ZEDQA rt_cards DONE")
    return
end

local Q = RT.make("rt_cards")
local S = { placed = {}, built = {}, fires = {}, used = {}, stackWas = {}, things = {} }
local H = {}
S.p, S.pn = RT.p, RT.pn
S.F = RT.focus()
S.ST = ZeD.Stations
S.CT = ZeD.ContainerControls
-- (Nov 18 2026: the diagonals too. The World window gathers the 3x3 around the player (ZeD_WorldWindow), so a
-- container it must list sits in RING1; the stove was in RING2 and never listed)
S.RING1 = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, -1 }, { 1, -1 }, { -1, 1 } }
-- the rain collector's fallback: within the 2 tiles the card's Wash looks for water (ItemCard.lua waterInReach);
-- it is tried in RING1 first (Nov 18 2026: adjacent, so the game's walk to it is short)
S.NEAR = { { 2, 1 }, { -2, -1 }, { 1, 2 }, { -1, -2 }, { 2, -1 }, { -2, 1 }, { 1, -2 }, { -1, 2 } }
S.RING2 = { { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 }, { 2, 2 }, { -2, -2 }, { 2, -2 }, { -2, 2 }, { 3, 0 }, { -3, 0 } }
S.BUILD = { { 4, -4 }, { -4, -4 }, { 4, 4 }, { -4, 4 }, { 5, 0 }, { -5, 0 }, { 0, -5 }, { 0, 5 } }

-- ===================================================================== helpers
function H.px(n) return ZeD.T.px(n) end
function H.cardW(w)
    -- (a drawer is 220 or 480, nothing else: FEATURE_MAP, "Drawer widths"; the 260 in the code is the drawer's speed)
    for _, n in ipairs({ 220, 480 }) do if math.abs((w or 0) - H.px(n)) <= 1 then return true end end
    return false
end
function H.full(w) return math.abs((w or 0) - H.px(480)) <= 1 end
function H.queueHead()
    local t = "none"
    pcall(function()
        local q = ISTimedActionQueue.getTimedActionQueue(S.p)
        local a = q and q.queue and q.queue[1]
        if a then t = tostring(a.Type) end
    end)
    return t
end
function H.stopActions() pcall(function() S.p:StopAllActionQueue() end) end
function H.nm(it)
    if it == nil then return "nil" end   -- (under -debug a nil indexed inside pcall still logs a Java exception)
    local n = nil
    pcall(function() n = it:getDisplayName() end)
    return tostring(n or it)
end

-- the Character window's list and an item's row in it (its hit zone: the row's id is the item)
function H.content() local w = RT.cw(); return w and w._mainContent end
function H.rowZone(item)
    local c = H.content()
    for _, z in ipairs((c and c._hitZones) or {}) do if z.id == item then return z end end
    return nil
end
-- a point of the row's zone that a press reaches (the list's hitZoneAt answers the row there). A row half under the
-- heading or the footer band (Nov 22 2026: transfer buttons in the footer) gives its press to what is drawn over it,
-- so the zone's middle is not enough (the Deck, Nov 22: a press there went to the band and the pencil left the bag)
function H.clickPoint(c, z, item)
    if not (c and z and c.hitZoneAt) then return nil end
    local x = z.x + math.floor(z.w / 2)
    for _, f in ipairs({ 0.5, 0.3, 0.7, 0.15, 0.85 }) do
        local y = z.y + math.floor(z.h * f)
        local hz = c:hitZoneAt(x, y)
        if hz ~= nil and hz.id == item then return x, y end
    end
    return nil
end
-- (a condition, every frame: the row drawn last frame where a press reaches it, else the list one step further down;
-- wraps at the end)
function H.seekRow(item)
    local c = H.content()
    if not c then return false end
    local z0 = H.rowZone(item)
    if z0 and H.clickPoint(c, z0, item) ~= nil then return true end
    local sc = c._scroll
    if sc and sc.setScrollPos then
        S.seekPos = (S.seekPos or -0.1) + 0.1
        if S.seekPos > 1.001 then S.seekPos = 0 end
        sc:setScrollPos(S.seekPos)
    end
    return false
end
-- a left click on the row, as the list's own mouse handlers take it
function H.click(item)
    local c = H.content()
    local z = H.rowZone(item)
    if not (c and z) then return false end
    local x, y = H.clickPoint(c, z, item)
    if not x then return false end
    c._zedLastClick = nil   -- (never a double-click: that would be the quick use)
    c:onMouseDown(x, y)
    c:onMouseUp(x, y)
    return true
end
-- queue: find the item's row (scrolling if need be), then click it
function H.queueClick(item, label)
    Q.step(2, function() S.seekPos = nil end)
    Q.waitFor(1, 240, function() return H.seekRow(S[item]) end, function(ok)
        Q.check(ok, label .. ": its row is in the Character window's list", H.nm(S[item]))
        if ok then H.click(S[item]) end
    end)
end
function H.card() local w = RT.cw(); return w and w._itemCard end
-- the card's Lists mark's rect, or nil: card._markRects.lists with the plug-in points (Nov 23 2026), else card._listsRect
function H.listsRect(c)
    if not c then return nil end
    local mr = c._markRects
    if type(mr) == "table" then return mr.lists end
    return c._listsRect
end
-- the table that holds the Loadouts switch (loadoutsOption, restockOption): the add-on's ZeDLoadouts where it is
-- loaded (Nov 23 2026, the split), else ZeD.Settings (Loadouts built in)
function H.loadOpt()
    local LO = ZeDLoadouts
    if type(LO) == "table" and LO.loadoutsOption then return LO end
    return ZeD.Settings
end
function H.cardOn(item)
    local w = RT.cw()
    local c = w and w._itemCard
    return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
end
function H.row(rows, label)
    for _, r in ipairs(rows or {}) do if r.label == label then return r end end
    return nil
end
function H.factRow(panel, label)
    for _, g in ipairs((panel and panel.groups) or {}) do
        for _, r in ipairs(g.rows or {}) do if r.label == label then return r end end
    end
    return nil
end
function H.verbIdx(id)
    local c = H.card()
    for i, v in ipairs((c and c._lastHeaderVerbs) or {}) do if v.id == id then return i end end
    return nil
end
function H.ctxMenu()
    local m = nil
    pcall(function() local v = getPlayerContextMenu(S.pn); m = v and v._zedMenu end)
    return m
end
-- a menu of ZeD's on screen: the strip by RT.bounds, the list (a full-screen layer RT.bounds skips) by its levels
function H.menuOnScreen(m, label)
    RT.bounds(Q, label)
    if not (m and m._levels) then return end
    local W, Hs = getCore():getScreenWidth(), getCore():getScreenHeight()
    local bad = {}
    for i, lv in ipairs(m._levels) do
        if lv.x < -1 or lv.y < -1 or lv.x + lv.w > W + 1 or lv.y + lv.h > Hs + 1 then
            bad[#bad + 1] = string.format("level %d at %d,%d %dx%d", i, math.floor(lv.x), math.floor(lv.y), math.floor(lv.w), math.floor(lv.h))
        end
    end
    Q.check(#bad == 0, "on screen (" .. label .. "): every level of the list", (#bad == 0) and (#m._levels .. " levels") or table.concat(bad, "; "))
end
-- focus a stop of the card by its id (FocusManager, charItemCard)
function H.focusCardId(id)
    local w = RT.cw()
    if not (w and S.F and S.F.focusWhere) then return false end
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "charItemCard", function(el) return el.id == id end) end)
    return e ~= nil
end
-- the text prompt up (ZeD's prompt, or vanilla's box in safe mode)
function H.textPrompt()
    return RT.find(function(t) return (t.Type == "ZeD_Prompt" and t.kind == "text") or (t.Type == "ISTextBox" and t.entry ~= nil) end)
end
function H.promptAnswer(t, yes, text)
    if text and t.entry then pcall(function() t.entry:setText(text) end) end
    if t.pressPrimary then
        if yes then t:pressPrimary() else t:answerCancel() end
    else
        t:onClick(yes and t.yes or t.no)
    end
end
-- a field of a panel somewhere under root (the Equip tab keeps its card on its panel)
function H.findField(el, key, depth)
    if type(el) ~= "table" or depth > 8 then return nil end
    if el[key] ~= nil then return el[key] end
    for _, ch in pairs(el.children or {}) do
        local r = H.findField(ch, key, depth + 1)
        if r ~= nil then return r end
    end
    return nil
end
function H.verbIds()
    local out = {}
    local c = H.card()
    for _, v in ipairs((c and c._lastHeaderVerbs) or {}) do out[#out + 1] = tostring(v.id) end
    return table.concat(out, " ")
end

-- ===================================================================== the pad
function H.padOn()
    pcall(function() local md = S.p:getModData().ZeD_Gamepad; S.lockWas = md and md.inputModeLock end)
    pcall(function() ZeD.Input.Detector.setLockedMode("gamepad") end)
    local w = RT.cw()
    if w and S.F and S.F.claimFocus then pcall(S.F.claimFocus, w) end
    S.padIsOn = true
end
function H.padOff()
    if not S.padIsOn then return end
    S.padIsOn = nil
    RT.pad("A", nil)
    pcall(function() S.F.releaseFocus(S.pn) end)
    pcall(function()
        local Dt = ZeD.Input.Detector
        Dt.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then Dt.setLockedMode(S.lockWas) end
    end)
end
function H.focusRow(item)
    local w = RT.cw()
    if not (w and S.F and S.F.focusWhere and item) then return false end
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "charMainInv", function(el) return el.item == item end) end)
    return e ~= nil
end
function H.focusVerb(id)
    local w = RT.cw()
    local idx = H.verbIdx(id)
    if not (w and S.F and S.F.focusWhere and idx) then return false end
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "charItemCard", function(el) return el.id == "hverb_" .. idx end) end)
    return e ~= nil
end
-- queue: A down (the QA hook holds it, FocusManager's dispatch takes the press), up after holdMs (0: a tap), let go
-- (S.armA false: the focus did not land where it should, so no A is pressed on whatever holds it instead)
function H.queueA(holdMs, note)
    Q.step(1, function()
        if S.armA == false then return end
        RT.pad("A", true); RT.padDown(Joypad.AButton, RT.cw())
    end)
    -- (note: one frame after A, the queue's action types said in a NOTE line)
    if note then
        Q.step(1, function()
            if S.armA == false then return end
            Q.say("NOTE " .. tostring(note) .. ": one frame after A the queue holds " .. H.queueTypes())
        end)
    end
    if holdMs and holdMs > 0 then Q.waitMs(holdMs) else Q.step(4, function() end) end
    Q.step(1, function() RT.pad("A", false) end)
    Q.step(4, function() RT.pad("A", nil); S.armA = nil end)
end
-- queue: a card verb pressed on the pad (focus on it, then A tapped or held)
function H.queueVerb(id, label, holdMs)
    Q.waitFor(2, 120, function() return H.verbIdx(id) ~= nil end, function(ok)
        S.armA = (ok and H.focusVerb(id)) and true or false
        Q.check(S.armA, label .. ": the card shows " .. id .. " and the pad's focus lands on it", H.verbIds())
    end)
    H.queueA(holdMs)
end

-- ===================================================================== the world
function H.sq(dx, dy)
    return getCell():getGridSquare(math.floor(S.p:getX()) + dx, math.floor(S.p:getY()) + dy, math.floor(S.p:getZ()))
end
-- (Nov 18 2026: a square is marked used only once something is placed on it (H.useSq), and by where it is, not by
-- its offset: the character walks (Add fuel, Light) and the offsets move with them. A failed placement used to
-- burn the square.)
function H.sqKey(sq) return sq:getX() .. "," .. sq:getY() .. "," .. sq:getZ() end
function H.useSq(sq) if sq then S.used[H.sqKey(sq)] = true end end
function H.freeSq(offsets)
    for _, o in ipairs(offsets) do
        local sq = H.sq(o[1], o[2])
        local free = false
        if sq and not S.used[H.sqKey(sq)] then
            pcall(function() free = sq:isFree(false) and not sq:HasTree() and sq:getVehicleContainer() == nil end)
        end
        if free then return sq end
    end
    return nil
end
function H.ocard() local c = nil; pcall(function() c = ZeD_WorldWindow.getObjectCard(S.pn) end); return c end
function H.entry() local c = H.ocard(); return c and c.entry end
function H.kind() local e = H.entry(); return e and e.def and e.def.id end
function H.closeCard() pcall(function() ZeD_WorldWindow.closeObjectCard(S.pn) end) end
function H.pill(e)
    if not (e and e.def and e.def.pill) then return nil end
    local ok, words = pcall(e.def.pill, e.t)
    return ok and words or nil
end
function H.wcontent() local w = RT.ww(); return w and w._mainContent end
function H.inList(inv)
    local w = RT.ww()
    for _, c in ipairs((w and w._containers) or {}) do if c.inventory == inv then return c end end
    return nil
end
function H.ccIdx(key)
    local c = H.wcontent()
    for i, h in ipairs((c and c._cc and c._cc.hits) or {}) do if h.key == key then return i end end
    return nil
end
function H.ccKeys()
    local out = {}
    local c = H.wcontent()
    for _, h in ipairs((c and c._cc and c._cc.hits) or {}) do out[#out + 1] = tostring(h.key) end
    return table.concat(out, " ")
end
function H.removeObj(obj)
    if not obj then return end
    local sq = nil
    pcall(function() sq = obj:getSquare() end)
    if sq then
        pcall(function() sq:transmitRemoveItemFromSquare(obj) end)
        pcall(function() if obj:getObjectIndex() >= 0 then sq:RemoveTileObject(obj) end end)
    end
    pcall(function() if instanceof(obj, "IsoGenerator") then obj:remove() end end)
end
function H.campLua(sq)
    local lo = nil
    pcall(function() lo = CCampfireSystem.instance:getLuaObjectOnSquare(sq) end)
    return lo
end
-- the game's laundry tile for a class (by the tile's IsoType, as zedqa_laundry.lua finds it)
function H.laundryTile(cls)
    for i = 0, 47 do
        local name = "appliances_laundry_01_" .. i
        local spr = getSprite(name)
        local props = spr and spr:getProperties()
        if props and props:has("IsoType") and props:get("IsoType") == cls then return name end
    end
    return nil
end
-- a container tile object (the fridge): the first sprite that makes a container
function H.tileObject(sq, sprites)
    for _, name in ipairs(sprites) do
        if sq and getSprite(name) then
            local o = IsoObject.new(sq, name, nil, false)
            sq:AddTileObject(o)
            pcall(function() o:createContainersFromSpriteProperties() end)
            if o:getContainer() then return o end
            pcall(function() sq:transmitRemoveItemFromSquare(o) end)
        end
    end
    return nil
end
-- an entity built with the game's build code (the build cheat), as zedqa_b8_station.lua builds; returns the new objects
function H.findInfo(full)
    local infos = SpriteConfigManager.GetObjectInfoList()
    for i = 0, infos:size() - 1 do
        local info = infos:get(i)
        local parent = info:getScript() and info:getScript():getParent()
        if parent and tostring(parent:getScriptObjectFullType()) == full then return info end
    end
    return nil
end
function H.snapshot(cx, cy, r)
    local set = {}
    for y = cy - r, cy + r do
        for x = cx - r, cx + r do
            local sq = getCell():getGridSquare(x, y, math.floor(S.p:getZ()))
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do set[objs:get(i)] = true end
            end
        end
    end
    return set
end
function H.build(full, offsets)
    local info = H.findInfo(full)
    if not info then return nil, "no entity info for " .. full end
    local px, py, pz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for _, o in ipairs(offsets or S.BUILD) do
        local x, y = px + o[1], py + o[2]
        local before = H.snapshot(x, y, 2)
        S.p:setBuildCheat(true)
        local okB = pcall(function()
            local b = ISBuildIsoEntity:new(S.p, info, 1, ISInventoryPaneContextMenu.getContainers(S.p))
            b.buildCheat = true
            b.player = S.pn
            local sq = getCell():getGridSquare(x, y, pz)
            b.sq = sq
            if b:isValid(sq) then b:create(x, y, pz, false, nil) end
        end)
        S.p:setBuildCheat(false)
        if okB then
            local new = {}
            for obj in pairs(H.snapshot(x, y, 2)) do
                if not before[obj] then new[#new + 1] = obj; S.built[#S.built + 1] = obj end
            end
            if #new > 0 then H.useSq(getCell():getGridSquare(x, y, pz)); return new end
        end
    end
    return nil, "no room to build " .. full
end
function H.closeGameStationWindows()
    pcall(function()
        local pl = ISEntityUI.players and ISEntityUI.players[S.pn]
        for _, w in pairs((pl and pl.windows) or {}) do
            if w and w.instance then
                local inst = w.instance
                pcall(function() if inst.close then inst:close() else inst:removeFromUIManager() end end)
            end
        end
    end)
end

-- ===================================================================== setup
Q.step(2, function()
    if getGameSpeed() <= 0 then pcall(setGameSpeed, 1) end
    S.pairWas = RT.isOpen()
    RT.pairOpen()
    S.handWas = { S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem() }
    H.stopActions()
    S.apple = RT.give("Base.Apple")
    S.bat = RT.give("Base.BaseballBat")
    S.book = RT.give("Base.Book")
    S.pencil = RT.give("Base.Pencil")
    Q.check(S.apple and S.bat and S.book and S.pencil, "an apple, a bat, a book and a pencil are given",
        H.nm(S.apple) .. ", " .. H.nm(S.bat) .. ", " .. H.nm(S.book) .. ", " .. H.nm(S.pencil))
end)
Q.step(20, function()
    RT.worldTab("loot")
    local c = H.content()
    Q.check(c ~= nil and c._inventory == S.p:getInventory(), "the Character window's list shows the main inventory",
        tostring(c and c._inventory and c._inventory:getType()))
    if c then
        -- no card up to start with (nothing selected in the list)
        local w = RT.cw()
        if w and w._drawerItem and w._updateDrawer then
            c._selectedItems = {}
            c._lastClickedItem = nil
            pcall(w._updateDrawer, c)
        end
        S.scrollWas = c._scroll and c._scroll.scrollPos
        -- each thing on its own row: its stack opened (put back after)
        c._expandedStacks = c._expandedStacks or {}
        -- (a stack's key is its full type: InventoryRenderer's itemModel)
        for _, k in ipairs({ "apple", "bat", "book", "pencil" }) do
            local ft = nil
            pcall(function() ft = S[k]:getFullType() end)
            if ft then
                if S.stackWas[ft] == nil then S.stackWas[ft] = c._expandedStacks[ft] or false end
                c._expandedStacks[ft] = true
            end
        end
    end
end)

-- (the pad first, with no card open: a row focused while a card is up swaps the card to it at once, and A on a
-- row whose card is up opens the game's menu instead)
-- ===================================================================== item card: the pad
Q.step(2, function() H.padOn() end)
Q.waitFor(4, 120, function() return H.focusRow(S.apple) end, function(ok)
    S.armA = ok and true or false
    Q.check(ok, "pad: the focus lands on the apple's row (FocusManager, charMainInv)")
end)
H.queueA(0)
Q.waitFor(2, 120, function() return H.cardOn(S.apple) end, function(ok)
    local c = H.card()
    Q.check(ok, "pad: A on the apple's row opens its card", H.nm(c and c.item))
    Q.check(c and H.cardW(c:getWidth()), "pad: the card is half or full wide", c and math.floor(c:getWidth()))
    RT.bounds(Q, "the apple's item card (pad)")
end)
-- A again on the row whose card is open: the game's menu for it (InventoryRenderer.padCardOpen), ZeD's menu, on screen
Q.waitFor(4, 120, function() return H.focusRow(S.apple) end, function(ok)
    S.armA = ok and H.cardOn(S.apple)
    Q.check(S.armA, "pad: the focus goes back to the apple's row, its card still open")
end)
H.queueA(0)
Q.waitFor(2, 120, function() return H.ctxMenu() ~= nil end, function(ok)
    local m = H.ctxMenu()
    local on = false
    for _, t in ipairs((m and m._ctx and type(m._ctx.target) == "table") and m._ctx.target or {}) do if t == S.apple then on = true end end
    Q.check(ok and on, "pad: A on the row whose card is open opens the game's menu for the apple (ZeD's menu)",
        "menu " .. tostring(m and m.Type) .. ", on the apple " .. tostring(on))
    H.menuOnScreen(m, "the apple's menu (pad A)")
    if m then pcall(function() m:close() end) end
end)

-- Eat: A held on the card's Eat (the game's ISEatFoodAction)
-- (QA, Nov 23 2026: other runs that eat leave him full, the card then reads "Eat more" and the game queues nothing:
-- he is made a little hungry for this step and his hunger put back after it)
Q.step(10, function()
    pcall(function() S.hungerWas = S.p:getStats():get(CharacterStat.HUNGER) end)
    pcall(function() S.p:getStats():set(CharacterStat.HUNGER, 0.3) end)
end)
H.queueVerb("EAT", "eat", 600)
Q.waitFor(2, 120, function() return H.queueHead() == "ISEatFoodAction" end, function(ok)
    Q.check(ok, "eat: A held on Eat queues the game's own eat (ISEatFoodAction)", H.queueHead())
    H.stopActions()
    if S.hungerWas ~= nil then pcall(function() S.p:getStats():set(CharacterStat.HUNGER, S.hungerWas) end) end
end)

-- ===================================================================== item card: the mouse
Q.step(10, function() end)
H.queueClick("bat", "mouse")
Q.waitFor(2, 120, function() return H.cardOn(S.bat) and H.cardW(H.card():getWidth()) end, function(ok)
    local c = H.card()
    Q.check(H.cardOn(S.bat), "mouse: a click on the bat's row opens its card", H.nm(c and c.item))
    Q.check(c and H.cardW(c:getWidth()), "mouse: the card is half (220) or full (480) wide", c and math.floor(c:getWidth()))
end)
Q.step(15, function()
    local c = H.card()
    local m = c and c._model
    -- (Nov 21 2026, B8-1b, a9ac61c8c: the card weighs an item as the lists and the game's tooltip do, getUnequippedWeight
    -- first; for a bat the same as the bare weight)
    local wt = nil
    pcall(function() wt = S.bat:getUnequippedWeight() end)
    if wt == nil then pcall(function() wt = S.bat:getActualWeight() end) end
    wt = wt or 0
    local want = string.format("%.1f kg", wt)
    local r = m and H.row(m.stats, ZeD.tr("UI_ZeD_Weight"))
    Q.check(r ~= nil and r.value == want, "facts: the card shows the bat's weight", tostring(r and r.value) .. " (want " .. want .. ")")
    local cond, cmax = 0, 0
    pcall(function() cond, cmax = S.bat:getCondition(), S.bat:getConditionMax() end)
    local wantC = string.format("%d / %d", cond, cmax)
    local fr = m and H.factRow(m.facts, getText("Tooltip_weapon_Condition"))
    Q.check(fr ~= nil and fr.value == wantC, "facts: the card's facts show the bat's condition", tostring(fr and fr.value) .. " (want " .. wantC .. ")")
    RT.bounds(Q, "the bat's item card")
    -- the width branch (ItemCardOrganism's widthPreset): the drawer's card is under 320 units, so the compact 220
    -- layout draws, its back bar and verbs stamped
    local bb = c and c._backBarRects
    Q.check(c ~= nil and c:getWidth() < H.px(320) and bb ~= nil and #(bb.verbs or {}) > 0 and c._nameRowRect ~= nil,
        "width: the drawer's card is the compact one (under 320) and it draws its name row, back bar and verbs",
        c and (math.floor(c:getWidth()) .. " wide, " .. #((bb and bb.verbs) or {}) .. " verbs"))
end)

-- rename from the name row: A on the card's stop "name_row" opens the rename prompt with the bat's name; OK takes
-- the typed name, Cancel leaves it (Overrides/ItemMenu.lua's rename). The bat's name is put back.
S.newName = "ZeD QA bat"
Q.step(2, function() pcall(function() S.batName = S.bat:getName() end) end)
Q.waitFor(2, 120, function() return H.focusCardId("name_row") end, function(ok)
    S.armA = ok and true or false
    Q.check(ok, "rename: the pad's focus lands on the card's name row (name_row)")
end)
H.queueA(0)
Q.waitFor(2, 120, function() return H.textPrompt() ~= nil end, function(ok)
    local t = H.textPrompt()
    local txt = nil
    pcall(function() txt = t.entry:getText() end)
    Q.check(ok and txt == S.batName, "rename: A on the name row opens the rename prompt with the bat's name", tostring(txt))
    RT.bounds(Q, "the rename prompt")
    if t then H.promptAnswer(t, true, S.newName) end
end)
Q.waitFor(2, 60, function() return H.textPrompt() == nil end, function(ok)
    local nm = nil
    pcall(function() nm = S.bat:getName() end)
    Q.check(ok and nm == S.newName, "rename: OK names the bat as typed", tostring(nm))
end)
Q.waitFor(4, 120, function() return H.focusCardId("name_row") end, function(ok) S.armA = ok and true or false end)
H.queueA(0)
Q.waitFor(2, 120, function() return H.textPrompt() ~= nil end, function(ok)
    local t = H.textPrompt()
    Q.check(ok, "rename: the prompt opens again")
    if t then H.promptAnswer(t, false, "ZeD QA not this") end
end)
Q.waitFor(2, 60, function() return H.textPrompt() == nil end, function(ok)
    local nm = nil
    pcall(function() nm = S.bat:getName() end)
    Q.check(ok and nm == S.newName, "rename: Cancel leaves the name as it was", tostring(nm))
    pcall(function() S.bat:setName(S.batName); S.bat:setCustomName(false) end)
end)

-- the Lists pop-up: A on the card's Lists mark (stop "toggle_lists") opens it beside the card, on screen. The mark
-- shows only while ZeD setup's Loadouts and outfits is on: it is turned on for this and put back.
-- (Nov 21 2026: Lite leaves the card's marks strip out, the Lists mark with it (ItemCardOrganism.lua renderBody, beta 21
-- Lite step 4; rt_lite checks the strip is gone). In Lite, with Loadouts on, the mark is checked absent and the pop-up is a SKIP.)
Q.step(2, function()
    S.liteCard = (ZeD.Settings and ZeD.Settings.lite and ZeD.Settings.lite()) and true or false
    local LT = H.loadOpt()
    local o = LT and LT.loadoutsOption
    S.noLists = (o == nil)
    if o then
        S.loadWas = o:getValue()
        if S.loadWas ~= 2 then pcall(function() o:setValue(2) end) end
    end
end)
Q.waitFor(4, 240, function() return S.liteCard or S.noLists or H.focusCardId("toggle_lists") end, function(ok)
    if S.noLists then
        S.armA = false
        Q.skip("lists: the card shows its Lists mark and the pad's focus lands on it (toggle_lists)",
            "ZeD-GUI: Loadouts is not loaded: since the split the Lists mark is the add-on's (ad_split checks ZeD alone has none)")
        return
    end
    if S.liteCard then
        S.armA = false
        local on = H.cardOn(S.bat)
        Q.check(on and H.listsRect(H.card()) == nil and not H.focusCardId("toggle_lists"),
            "lists (Lite): the card has no Lists mark and the pad has no stop for it (toggle_lists)",
            "card " .. tostring(on) .. ", Loadouts on " .. tostring(ZeD.Lists and ZeD.Lists.on()))
        return
    end
    S.armA = ok and true or false
    Q.check(ok, "lists: the card shows its Lists mark and the pad's focus lands on it (toggle_lists)", tostring(ZeD.Lists and ZeD.Lists.on()))
end)
H.queueA(0)
Q.waitFor(2, 120, function() local LU = ZeD.ListsUI; return S.liteCard or S.noLists or (LU and LU.popup and LU.popup._ctx and LU.popup._ctx.open) end, function(ok)
    local m = ZeD.ListsUI and ZeD.ListsUI.popup
    if S.noLists then
        ok = false
        Q.skip("lists: A on the Lists mark opens the lists' pop-up", "ZeD-GUI: Loadouts is not loaded")
    elseif S.liteCard then
        ok = false
        Q.skip("lists: A on the Lists mark opens the lists' pop-up", "Lite: the item card has no Lists mark")
    else
        Q.check(ok, "lists: A on the Lists mark opens the lists' pop-up", tostring(m and m.headText))
    end
    if ok then
        H.menuOnScreen(m, "the Lists pop-up")
        local c = H.card()
        local lv = m._levels and m._levels[1]
        local cx = c and c:getAbsoluteX()
        Q.check(lv ~= nil and cx ~= nil and lv.x + lv.w >= cx and lv.x <= cx + c:getWidth() + H.px(8),
            "lists: the pop-up opens at the card (from the mark's lower left)",
            lv and (math.floor(lv.x) .. "+" .. math.floor(lv.w) .. " vs card " .. tostring(cx and math.floor(cx))))
        pcall(function() m:close() end)
    end
    local LT = H.loadOpt()
    local o = LT and LT.loadoutsOption
    if o and S.loadWas then pcall(function() o:setValue(S.loadWas) end) end
end)

-- Read: the book's card by the mouse, Read by the pad (ISReadABook)
Q.waitMs(600)
H.queueClick("book", "read")
Q.waitFor(2, 120, function() return H.cardOn(S.book) end, function(ok)
    Q.check(ok, "read: a click on the book's row opens its card", H.nm(H.card() and H.card().item))
end)
Q.step(10, function() end)
H.queueVerb("READ", "read", 0)
Q.waitFor(2, 120, function() return H.queueHead() == "ISReadABook" end, function(ok)
    Q.check(ok, "read: Read queues the game's own read (ISReadABook)", H.queueHead())
    H.stopActions()
end)

-- Equip: the bat's card again, Equip (the game's equip: the bat in the hand)
Q.waitMs(600)
H.queueClick("bat", "equip")
Q.waitFor(2, 120, function() return H.cardOn(S.bat) end, function(ok)
    Q.check(ok, "equip: the bat's card opens again", H.nm(H.card() and H.card().item))
end)
Q.step(10, function() end)
H.queueVerb("EQUIP", "equip", 0)
Q.waitFor(2, 900, function() return S.p:getPrimaryHandItem() == S.bat end, function(ok)
    Q.check(ok, "equip: Equip puts the bat in the hand (the game's equip action)", H.nm(S.p:getPrimaryHandItem()))
    local c = H.card()
    local ctx = nil
    pcall(function() ctx = c:_effectiveContext() end)
    Q.check(ctx == "equipped", "equip: the card now reads the bat as equipped", tostring(ctx))
    H.stopActions()
end)

-- the full card (ItemCardOrganism's 480 branch): the Equip tab, A on the primary hand's slot (stop slotType "PRI" in
-- charTabContent), its card at 480 with its back bar and verbs drawn; its back key returns to the list
Q.step(10, function()
    local w = RT.cw()
    S.charTabWas = w and w._activeTab
    if not RT.charTab("equip") then Q.check(false, "width: the Character window has the Equip tab", table.concat(RT.tabs(RT.charStrip()), " ")) end
end)
Q.waitFor(10, 240, function()
    local w = RT.cw()
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "charTabContent", function(el) return el.slotType == "PRI" end) end)
    return e ~= nil
end, function(ok)
    S.armA = ok and true or false
    if not ok then
        -- (the doll view lists no PRI row: the slot opened as its own stop's onActivate opens it)
        local w = RT.cw()
        Q.say("NOTE no PRI stop in the Equip tab: the primary hand's slot opened as its stop does")
        if w then w._equipSelected = "PRI"; w._equipCache = nil end
    end
end)
H.queueA(0)
Q.waitFor(4, 300, function()
    local card = H.findField(RT.cw(), "_equipCard", 0)
    return card ~= nil and card.item == S.bat and card:isVisible() and card._backBarRects ~= nil
end, function(ok)
    local card = H.findField(RT.cw(), "_equipCard", 0)
    local bb = card and card._backBarRects
    Q.check(ok and H.full(card:getWidth()) and #((bb and bb.verbs) or {}) > 0,
        "width: the Equip tab opens the bat's card at full width (480) and it draws its back bar and verbs",
        card and (math.floor(card:getWidth()) .. " wide, item " .. H.nm(card.item)) or "no card")
    RT.bounds(Q, "the Equip tab's card")
    if card and card.onBackClick then pcall(card.onBackClick, card) end
end)
Q.step(4, function()
    local w = RT.cw()
    Q.check(w ~= nil and w._equipSelected == nil, "width: the card's back key returns the Equip tab to its list")
    if w then w._equipSelected = nil end
    if S.charTabWas and S.charTabWas ~= "equip" then RT.charTab(S.charTabWas) end
end)

-- Drop: the pencil's card, Drop (the game's drop: it leaves the inventory)
Q.waitMs(600)
H.queueClick("pencil", "drop")
Q.waitFor(2, 120, function() return H.cardOn(S.pencil) end, function(ok)
    Q.check(ok, "drop: a click on the pencil's row opens its card", H.nm(H.card() and H.card().item))
end)
Q.step(10, function() end)
-- (Nov 18 2026, Build: by design an item not worn or held shows its primary verb and MORE; MORE opens the item's
-- whole context menu at the button, and Drop is there, the game's ContextMenu_Drop. So: MORE, then that row.)
function H.ctxPick(m, nm)
    local function same(a, b) return a == b or string.lower(tostring(a)) == string.lower(tostring(b)) end
    if m._levels then
        local lv = m._levels[1]
        if not lv then return false, "no level 1" end
        local ri = nil
        for k, r in ipairs(lv.rows or {}) do if not ri and r.def and same(r.def.name, nm) then ri = k end end
        if not ri then return false, "no row " .. tostring(nm) end
        lv.sel = ri
        m:confirm(1)
        return true, "picked"
    end
    local idx = nil
    for i, d in ipairs(m._ctx and m._ctx.items or {}) do if not idx and d and same(d.name, nm) then idx = i end end
    if not idx then return false, "no cell " .. tostring(nm) end
    m._ctx.selected = idx
    m:confirm()
    return true, "picked"
end
H.queueVerb("MORE", "drop", 0)
Q.waitFor(2, 120, function() return H.ctxMenu() ~= nil end, function(ok)
    Q.check(ok, "drop: MORE opens the pencil's whole context menu", tostring(ok))
    local m = H.ctxMenu()
    local on = false
    for _, t in ipairs((m and m._ctx and type(m._ctx.target) == "table") and m._ctx.target or {}) do if t == S.pencil then on = true end end
    Q.check(m ~= nil and on and m:isVisible(), "more: the menu MORE opens is the pencil's, and it shows", tostring(m and m.Type) .. ", on the pencil " .. tostring(on))
    H.menuOnScreen(m, "the pencil's MORE menu")
    local nm = getTextOrNull("ContextMenu_Drop") or "Drop"
    local okP, why = false, "no menu"
    if m then okP, why = H.ctxPick(m, nm) end
    Q.check(okP, "drop: the menu has the game's Drop and it can be picked", tostring(why))
end)
Q.waitFor(2, 900, function() return not S.p:getInventory():contains(S.pencil) end, function(ok)
    local wi, cont = nil, nil
    pcall(function() wi = S.pencil:getWorldItem() end)
    pcall(function() cont = S.pencil:getContainer() and S.pencil:getContainer():getType() end)
    Q.check(ok and (wi ~= nil or cont == "floor"), "drop: Drop puts the pencil on the ground (the game's drop action)",
        "world item " .. tostring(wi ~= nil) .. ", container " .. tostring(cont))
    H.stopActions()
end)
-- (Nov 18 2026, the ledger's row "Item card: tool verbs (Repair, Repair all, Pad all, Sharpen, Wash)": the card's
-- body verbs (stops verb_<key>) on a dull hunting knife with a whetstone, and on a dirty T-shirt (one hole) with a
-- needle, thread and rags and a barrel of water beside the character: each A queues the game's own action, which is
-- stopped. Repair on the knife: the game has no fixing for it, so the card hides the verb (checked absent).)
function H.queueHas(pat)
    local found = false
    pcall(function()
        local q = ISTimedActionQueue.getTimedActionQueue(S.p)
        for _, a in ipairs((q and q.queue) or {}) do if string.find(tostring(a.Type), pat, 1, true) then found = true end end
    end)
    return found
end
function H.queueTypes()
    local t = {}
    pcall(function()
        local q = ISTimedActionQueue.getTimedActionQueue(S.p)
        for _, a in ipairs((q and q.queue) or {}) do t[#t + 1] = tostring(a.Type) end
    end)
    return (#t > 0) and table.concat(t, " ") or "none"
end
Q.step(4, function()
    H.stopActions()
    -- (Nov 18 2026: Base.Tshirt_White is not in B42; Base.Tshirt_DefaultTEXTURE is the plain T-shirt)
    S.knife, S.shirt = RT.give("Base.HuntingKnife"), RT.give("Base.Tshirt_DefaultTEXTURE")
    for _, ft in ipairs({ "Base.Whetstone", "Base.Needle", "Base.Thread", "Base.RippedSheets", "Base.RippedSheets", "Base.RippedSheets" }) do RT.give(ft) end
    if S.knife then pcall(function() S.knife:setSharpness(0.3) end) end
    if S.shirt then
        pcall(function() S.shirt:setDirtiness(60) end)
        pcall(function()
            local parts = S.shirt:getCoveredParts()
            if parts and parts:size() > 0 then S.shirt:getVisual():setHole(parts:get(0)) end
        end)
    end
    local c = H.content()
    for _, k in ipairs({ "knife", "shirt" }) do
        local ft = nil
        if S[k] then pcall(function() ft = S[k]:getFullType() end) end
        if c and ft then
            c._expandedStacks = c._expandedStacks or {}
            if S.stackWas[ft] == nil then S.stackWas[ft] = c._expandedStacks[ft] or false end
            c._expandedStacks[ft] = true
        end
    end
    -- the water: a rain collector (the game's entity Base.RainCollector, built with the game's build code as the
    -- kiln is) within 2 tiles of the character, its fluid container filled. (Nov 18 2026: a bare IsoObject barrel
    -- has no fluid component, so it never held water.) It goes in the put-back with what was built.
    -- (Nov 18 2026, Build: ZeD's Wash calls the game's onWashClothing with the water object, which queues a walk
    -- (ISPathFindAction) then ISWashClothing; 2 tiles off, the walk could fail. Built adjacent (RING1) now, NEAR
    -- kept as the fallback.)
    local spots = {}
    for _, o in ipairs(S.RING1) do spots[#spots + 1] = o end
    for _, o in ipairs(S.NEAR) do spots[#spots + 1] = o end
    local objs = H.build("Base.RainCollector", spots)
    for _, o in ipairs(objs or {}) do
        local m = o
        pcall(function() m = o:getMasterObject() or o end)
        if not S.barrel then
            pcall(function()
                local fc = m:getFluidContainer()
                if fc then fc:addFluid(Fluid.Water, fc:getCapacity()) end
                if m:hasWater() and m:getFluidAmount() > 0 then S.barrel = m end
            end)
        end
    end
    Q.check(S.knife ~= nil and S.shirt ~= nil and S.barrel ~= nil, "tool verbs: a dull knife, a whetstone, a dirty shirt, sewing things and a barrel of water",
        "knife " .. tostring(S.knife ~= nil) .. ", shirt " .. tostring(S.shirt ~= nil) .. ", water " .. tostring(S.barrel ~= nil))
end)
-- one body verb: the item's card by the mouse, the pad's focus on verb_<key>, A tapped; then check(ok, types)
-- (words: the action's name in the check's words, where the queued Type is spelled otherwise)
function H.toolVerb(item, vkey, label, pat, words)
    Q.waitMs(400)
    -- (Nov 18 2026, Build: a click on the row toggles its card, and the card was already up from the verb before
    -- (Wash, then Pad all on the same shirt), so the click shut it. The row is clicked only when its card is not up.)
    Q.step(2, function() S.seekPos = nil end)
    Q.waitFor(1, 240, function() return H.seekRow(S[item]) end, function(ok)
        Q.check(ok, label .. ": its row is in the Character window's list", H.nm(S[item]))
        if ok and not H.cardOn(S[item]) then H.click(S[item]) end
    end)
    Q.waitFor(2, 120, function() return H.cardOn(S[item]) end, function(ok) S.tvCard = ok end)
    Q.waitFor(4, 240, function() return not S.tvCard or H.focusCardId("verb_" .. vkey) end, function(ok)
        S.armA = (S.tvCard and ok) and true or false
        Q.check(S.armA, label .. ": the card offers " .. vkey .. " and the pad's focus lands on it")
    end)
    H.queueA(0, label)
    Q.waitFor(2, 300, function() return H.queueHas(pat) end, function(ok)
        Q.check(ok, label .. ": A on it queues the game's own action (" .. (words or pat) .. ")", H.queueTypes())
        H.stopActions()
    end)
end
-- (Nov 18 2026, Build: B42's SharpenBlade is a craftRecipe, run by the game's ISHandcraftAction; the old find of
-- "Craft" was case-sensitive and missed it. The check's words keep "Craft".)
H.toolVerb("knife", "sharpen", "sharpen", "ISHandcraftAction", "Craft")
-- (Nov 18 2026, Build: no B42 fixing covers a knife, so the card hides Repair by design (Disclose.split): the check
-- is that it is absent, once the card's stops are built)
Q.waitMs(400)
Q.step(2, function() S.seekPos = nil end)
Q.waitFor(1, 240, function() return H.seekRow(S.knife) end, function(ok)
    Q.check(ok, "repair: its row is in the Character window's list", H.nm(S.knife))
    -- (the knife's card is still up from Sharpen: a click on its row then would not be needed)
    if ok and not H.cardOn(S.knife) then H.click(S.knife) end
end)
Q.waitFor(2, 120, function() return H.cardOn(S.knife) end, function(ok) S.tvCard = ok end)
Q.step(20, function()
    local has = S.tvCard and H.focusCardId("verb_repair")
    Q.check(S.tvCard and not has, "repair: with no fixing for the knife, the card offers no repair (verb_repair)",
        "card " .. tostring(S.tvCard) .. ", repair stop " .. tostring(has))
end)
H.toolVerb("shirt", "wash", "wash", "ISWashClothing")
H.toolVerb("shirt", "pad_all", "pad all", "ISRepairClothing")
H.toolVerb("shirt", "repair_all", "repair all", "ISRepairClothing")
Q.step(5, function() H.padOff() end)

-- ===================================================================== the recipe preview card
-- The World window's Craft tab (no station bound: the hand's recipes): a click on a recipe's row opens its craft
-- card, a click on the card's icon (zone "detailIcon", CraftingCore.openPreview) opens the preview card, half wide
-- (220); a click on another recipe closes it (ObjectCardPreview's valid follows the pick). Clicks go through the
-- tab's own click handler (ZeD.CraftingTab.onClick) at each zone's middle.
function H.craftState() local w = RT.ww(); return w and w._craftState end
function H.craftZone(kind, notId)
    local st = H.craftState()
    local lg = st and st._listGeo
    for _, z in ipairs((st and st.zones) or {}) do
        -- (Nov 18 2026: notId nil used to drop every zone with no id: the detail icon, the pop-out keys, the rack's)
        if z.type == kind and (notId == nil or z.id ~= notId) then
            local inView = (kind ~= "recipeRow") or (lg == nil) or (z.y >= lg.viewY and z.y + z.h <= lg.viewY + lg.viewH)
            if inView and z.w > 0 and z.h > 0 then return z end
        end
    end
    return nil
end
function H.craftClick(z)
    return pcall(ZeD.CraftingTab.onClick, RT.ww(), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
end
Q.step(5, function()
    RT.pairOpen()
    pcall(S.ST.unbind, S.p)
    H.closeCard()
    if not RT.worldTab("craft") then Q.check(false, "preview: the World window has the Craft tab", table.concat(RT.tabs(RT.worldStrip()), " ")) end
end)
Q.waitFor(10, 600, function() return H.craftZone("recipeRow") ~= nil end, function(ok)
    local z = H.craftZone("recipeRow")
    if not Q.check(ok, "preview: the Craft tab lists a recipe row in view") then return end
    S.recipe = z.id
    H.craftClick(z)
end)
Q.waitFor(4, 300, function() return S.recipe == nil or H.craftZone("detailIcon") ~= nil end, function(ok)
    if not S.recipe then return end
    local st = H.craftState()
    Q.check(ok and st and st.selected == S.recipe, "preview: a click on the recipe's row opens its craft card (the icon at its top)", tostring(st and st.selected))
    local z = H.craftZone("detailIcon")
    if z then H.craftClick(z) end
end)
Q.waitFor(2, 300, function() return S.recipe == nil or H.kind() == "preview" end, function(ok)
    if not S.recipe then return end
    local c = H.ocard()
    Q.check(ok, "preview: a click on the craft card's icon opens the recipe preview card", tostring(H.kind()))
    Q.check(c ~= nil and math.abs(c:getWidth() - H.px(220)) <= 1, "preview: the preview card is the half card (220)", c and math.floor(c:getWidth()))
    RT.bounds(Q, "the recipe preview card")
    local z = H.craftZone("recipeRow", S.recipe)
    S.recipe2 = z and z.id
    if z then H.craftClick(z) else Q.skip("preview: another recipe closes it", "only one recipe row in view") end
end)
Q.waitFor(2, 300, function() return S.recipe2 == nil or H.kind() ~= "preview" end, function(ok)
    if not S.recipe2 then return end
    local st = H.craftState()
    Q.check(ok and st and st.selected == S.recipe2, "preview: picking another recipe closes the preview card", tostring(H.kind()))
end)
Q.step(4, function()
    local st = H.craftState()
    pcall(function() if st and st.selected then ZeD.CraftingCore.closeCraft(st) end end)
    H.closeCard()
    RT.worldTab("loot")
end)

-- ===================================================================== object cards
Q.step(10, function()
    RT.pairOpen()
    RT.worldTab("loot")
    H.closeCard()
end)

-- the generator: the game's Info
Q.step(10, function()
    local sq = H.freeSq(S.RING2)
    if not sq then Q.check(false, "generator: a free square beside the character", "none"); return end
    pcall(function()
        S.gen = IsoGenerator.new(instanceItem("Base.Generator"), getCell(), sq)
        S.gen:setConnected(false); S.gen:setFuel(60); S.gen:setCondition(90)
    end)
    if S.gen then S.placed[#S.placed + 1] = S.gen; H.useSq(sq) end
    Q.check(S.gen ~= nil, "generator: placed beside the character")
    Q.check(ISWorldObjectContextMenu._zed_onInfoGenerator == true, "generator: ZeD's hook is on the game's Info")
end)
Q.step(10, function()
    if S.gen then pcall(ISWorldObjectContextMenu.onInfoGenerator, nil, S.gen, S.pn) end
end)
Q.waitFor(2, 300, function()
    local e, c = H.entry(), H.ocard()
    return S.gen == nil or (e and e.def.id == "generator" and e.t and e.t.d ~= nil and c and H.full(c:getWidth()))
end, function(ok)
    if not S.gen then return end
    local e, c = H.entry(), H.ocard()
    Q.check(e and e.def.id == "generator" and e.t.obj == S.gen, "generator: the game's Info opens ZeD's generator card on it", tostring(H.kind()))
    Q.check(c and H.full(c:getWidth()), "generator: the card is the full card (480)", c and math.floor(c:getWidth()))
    local d = e and e.t and e.t.d
    if d then
        local fuel, cond = 0, 0
        pcall(function() fuel, cond = S.gen:getFuel(), S.gen:getCondition() end)
        Q.check(math.abs((d.fuel or -1) - fuel) < 0.01 and d.cond == cond, "generator: the card reads its fuel and condition",
            tostring(d.fuel) .. " / " .. tostring(d.cond) .. " (want " .. tostring(fuel) .. " / " .. tostring(cond) .. ")")
        Q.check(d.on == false and H.pill(e) == ZeD.tr("UI_Off"), "generator: the card says it is off", tostring(H.pill(e)))
    end
    RT.bounds(Q, "the generator card")
    H.closeCard()
end)
-- (Nov 18 2026, the ledger's row "Generator card": the engine switch. Connected and fuelled, the face's switch
-- (zone gen:engine; the Simple card's Turn on verb when the face is off) runs the game's activate and the card reads
-- it on; again it stops; with no fuel the switch has nothing to run. Put back: unplugged, 60 fuel, off.)
function H.zoneFid(fid)
    local c = H.ocard()
    for _, z in ipairs((c and c._lastZones) or {}) do if z.fid == fid then return z end end
    for _, z in ipairs((c and c._zones) or {}) do if z.fid == fid then return z end end
    return nil
end
function H.verb(id)
    local e = H.entry()
    for _, v in ipairs((e and e.t and e.t.verbs) or {}) do if v.id == id then return v end end
    return nil
end
-- the engine switch pressed: its zone's run as a click fires it, else the power verb's
function H.genSwitch()
    local z = H.zoneFid("gen:engine")
    if z and z.run then return pcall(z.run, H.ocard(), S.p) end
    local v = H.verb("power")
    if v and v.run and v.enabled then return pcall(v.run, S.p, H.entry().t, H.ocard()) end
    return false
end
function H.genOn() local on = false; pcall(function() on = S.gen:isActivated() end); return on end
function H.genInfo() if S.gen then pcall(ISWorldObjectContextMenu.onInfoGenerator, nil, S.gen, S.pn) end end
Q.step(4, function()
    if not S.gen then return end
    pcall(function() S.gen:setConnected(true) end)
    H.genInfo()
end)
Q.waitFor(4, 300, function()
    local z, v = H.zoneFid("gen:engine"), H.verb("power")
    return S.gen == nil or (z ~= nil and z.run ~= nil) or (v ~= nil and v.enabled)
end, function(ok)
    if not S.gen then return end
    S.genArm = Q.check(ok, "generator: connected with fuel, its engine switch is live (gen:engine)")
    if S.genArm then H.genSwitch() end
end)
Q.waitFor(4, 1500, function() return not S.genArm or H.genOn() end, function(ok)
    if not S.genArm then return end
    Q.check(ok, "generator: the engine switch starts it (the game's own activate)")
    H.genInfo()
end)
Q.waitFor(4, 300, function() local e = H.entry(); return not S.genArm or (e and e.t and e.t.d and e.t.d.on == true) end, function(ok)
    if not S.genArm then return end
    local p = H.pill(H.entry())
    Q.check(ok and p ~= nil and p ~= ZeD.tr("UI_Off"), "generator: running, its card reads it on", tostring(p))
    H.genSwitch()
end)
Q.waitFor(4, 1500, function() return not S.genArm or not H.genOn() end, function(ok)
    if not S.genArm then return end
    Q.check(ok, "generator: the engine switch again stops it")
    pcall(function() S.gen:setFuel(0) end)
    H.genInfo()
end)
Q.waitFor(4, 300, function() local e = H.entry(); return not S.genArm or (e and e.t and e.t.d and e.t.d.fuel == 0 and e.t.d.on == false) end, function(ok)
    if not S.genArm then return end
    local z, v = H.zoneFid("gen:engine"), H.verb("power")
    Q.check(ok and (z == nil or z.run == nil) and not (v and v.enabled), "generator: with no fuel the engine switch refuses (nothing to run)",
        "zone run " .. tostring(z and z.run ~= nil) .. ", verb on " .. tostring(v and v.enabled))
    H.closeCard()
end)
Q.step(2, function()
    if not S.gen then return end
    pcall(function() if S.gen:isActivated() then S.gen:setActivated(false) end end)
    pcall(function() S.gen:setConnected(false); S.gen:setFuel(60) end)
end)

-- the campfire: the game's Info
Q.step(10, function()
    local sq = H.freeSq(S.RING2)
    if not sq then Q.check(false, "fire: a free square beside the character", "none"); return end
    local ok = pcall(function() SCampfireSystem.instance:addCampfire(sq) end)
    S.fires[#S.fires + 1] = sq
    S.fireSq = sq
    if ok then H.useSq(sq) end
    Q.check(ok, "fire: a campfire made beside the character (the game's campfire system)")
    Q.check(ISCampingMenu and ISCampingMenu._zed_onDisplayInfo == true, "fire: ZeD's hook is on the campfire's Info")
end)
Q.waitFor(5, 1200, function()
    local lo = S.fireSq and H.campLua(S.fireSq)
    return S.fireSq == nil or (lo ~= nil and lo:getIsoObject() ~= nil)
end, function(ok)
    if not S.fireSq then return end
    local lo = H.campLua(S.fireSq)
    local iso = lo and lo:getIsoObject()
    Q.check(ok and iso ~= nil, "fire: the campfire is in the world")
    if iso then pcall(ISCampingMenu.onDisplayInfo, nil, S.p, iso, lo) end
end)
Q.waitFor(2, 300, function()
    local e = H.entry()
    return S.fireSq == nil or (e and e.def.id == "fire" and e.t and e.t.d ~= nil)
end, function(ok)
    if not S.fireSq then return end
    local e = H.entry()
    Q.check(e and e.def.id == "fire" and e.t.kind == "campfire", "fire: the campfire's Info opens ZeD's fire card", tostring(H.kind()) .. " " .. tostring(e and e.t and e.t.kind))
    local d = e and e.t and e.t.d
    if d then
        Q.check(d.fuel == 0 and d.lit == false, "fire: a new campfire reads no fuel and not lit", tostring(d.fuel) .. " " .. tostring(d.lit))
        Q.check(H.pill(e) == ZeD.tr("UI_ZeD_Fire_PillOut"), "fire: the card says Out", tostring(H.pill(e)))
    end
    RT.bounds(Q, "the fire card")
    H.closeCard()
end)
-- (Nov 18 2026, the ledger's row "Fire card": Add fuel and Light. Planks, paper and matches given; the card's first
-- fuel row (zone fire:fuel:1, the game's ISAddFuelAction) adds fuel time; its first Light row (fire:light:1, the
-- game's light from tinder) lights it and the pill reads burning. The campfire goes in the put-back.)
function H.fireInfo()
    local lo = S.fireSq and H.campLua(S.fireSq)
    local iso = lo and lo:getIsoObject()
    if iso then pcall(ISCampingMenu.onDisplayInfo, nil, S.p, iso, lo) end
end
function H.fireD() local e = H.entry(); return (e and e.def and e.def.id == "fire" and e.t) and e.t.d or nil end
Q.step(4, function()
    if not S.fireSq then return end
    S.fireGiven = { RT.give("Base.Plank"), RT.give("Base.Plank"), RT.give("Base.SheetPaper2"), RT.give("Base.SheetPaper2"),
        RT.give("Base.SheetPaper2"), RT.give("Base.Matches") }
    H.fireInfo()
end)
Q.waitFor(4, 300, function() local z = H.zoneFid("fire:fuel:1"); return S.fireSq == nil or (z ~= nil and z.run ~= nil) end, function(ok)
    if not S.fireSq then return end
    S.fireArm = Q.check(ok, "fire: with fuel carried, the card lists it to add (fire:fuel:1)")
    if not S.fireArm then return end
    local d = H.fireD()
    S.fuel0 = d and d.fuel or 0
    pcall(H.zoneFid("fire:fuel:1").run, H.ocard(), S.p)
end)
Q.waitFor(4, 1800, function()
    if not S.fireArm then return true end
    local d = H.fireD()
    if not d then H.fireInfo() end
    return d ~= nil and d.fuel > S.fuel0
end, function(ok)
    if not S.fireArm then return end
    local d = H.fireD()
    Q.check(ok, "fire: Add fuel adds fuel time (the game's add fuel)", tostring(S.fuel0) .. " -> " .. tostring(d and d.fuel))
end)
Q.waitFor(4, 300, function() local z = H.zoneFid("fire:light:1"); return not S.fireArm or (z ~= nil and z.run ~= nil and not z.disabled) end, function(ok)
    if not S.fireArm then return end
    S.lightArm = Q.check(ok, "fire: with matches and paper, the card offers Light (fire:light:1)")
    if S.lightArm then pcall(H.zoneFid("fire:light:1").run, H.ocard(), S.p) end
end)
Q.waitFor(4, 2400, function()
    if not S.lightArm then return true end
    local d = H.fireD()
    if not d then H.fireInfo() end
    return d ~= nil and d.lit == true
end, function(ok)
    if not S.lightArm then return end
    local p = H.pill(H.entry())
    Q.check(ok and p ~= ZeD.tr("UI_ZeD_Fire_PillOut"), "fire: Light lights it (the game's light) and the pill reads burning", tostring(p))
    H.stopActions()
    H.closeCard()
end)
-- (Nov 18 2026, Build: a lit campfire's flame is the game's IsoFire, with no sprite. ZeD's hint strip asked the game's
-- getBestInteractButtonAction for every player every 200 ms, which reaches ISEntityUI.CanOpenWindowFor and its
-- getSprite():getName() on the flame: 424 Java exceptions in one run, for any player by a lit fire. Appliances.lua
-- now guards it. The fire stays lit a few seconds here, and the game's window check on the flame must answer no
-- with no error.)
Q.waitMs(3000)
Q.step(2, function()
    if not S.lightArm then return end
    local flame = nil
    pcall(function()
        local objs = S.fireSq:getObjects()
        for i = 0, objs:size() - 1 do
            local o = objs:get(i)
            if flame == nil and instanceof(o, "IsoFire") then flame = o end
        end
    end)
    if flame == nil then Q.skip("fire: a lit campfire's flame asked for a window", "no IsoFire on the fire's square"); return end
    local ok, r = pcall(ISEntityUI.CanOpenWindowFor, getPlayer(), flame)
    Q.check(ok and r == false, "fire: a lit campfire beside the character logs no exception (its flame has no window)",
        "pcall " .. tostring(ok) .. ", answer " .. tostring(r))
end)
-- put out the game's client way (CCampfireSystem; the server's SCampfireSystem:putOut is nil on the client, so the
-- first run's put-out never ran and the fire stayed lit)
Q.step(2, function()
    if not S.lightArm then return end
    pcall(function()
        local cf = CCampfireSystem.instance:getLuaObjectOnSquare(S.fireSq)
        if cf and cf.isLit then ISTimedActionQueue.add(ISPutOutCampfireAction:new(getPlayer(), cf)) end
    end)
end)
Q.waitFor(5, 600, function()
    if not S.lightArm then return true end
    local lit = false
    pcall(function() local cf = CCampfireSystem.instance:getLuaObjectOnSquare(S.fireSq); lit = cf ~= nil and cf.isLit == true end)
    return not lit
end, function(ok)
    if not S.lightArm then return end
    Q.check(ok, "fire: Put out puts the lit campfire out (the game's put-out action)")
    H.stopActions()
end)

-- the washer: its gears button on the container row
Q.step(10, function()
    local tile = H.laundryTile("IsoClothingWasher")
    local sq = H.freeSq(S.RING1)
    if not (tile and sq) then Q.check(false, "laundry: a washer tile and a free square beside the character", tostring(tile) .. " " .. tostring(sq ~= nil)); return end
    local ok = pcall(function()
        S.washer = IsoClothingWasher.new(getCell(), sq, getSprite(tile))
        pcall(function() S.washer:createContainersFromSpriteProperties() end)
        pcall(function() S.washer:createFluidContainersFromSpriteProperties() end)
        sq:AddSpecialObject(S.washer)
        if S.washer:getObjectIndex() < 0 then sq:AddTileObject(S.washer) end
    end)
    if S.washer then S.placed[#S.placed + 1] = S.washer; H.useSq(sq) end
    Q.check(ok and S.washer ~= nil and S.washer:getContainer() ~= nil, "laundry: a washer placed beside the character", tile)
    pcall(function() RT.ww()._containersDirty = true end)
end)
Q.waitFor(5, 600, function() return S.washer == nil or H.inList(S.washer:getContainer()) ~= nil end, function(ok)
    if not S.washer then return end
    Q.check(ok, "laundry: the washer is in the World window's container list")
    pcall(ZeD_WorldWindow.selectContainer, S.washer:getContainer(), 60, S.pn)
end)
Q.waitFor(5, 600, function() return S.washer == nil or H.ccIdx("obj:ZeDLaundry") ~= nil end, function(ok)
    if not S.washer then return end
    Q.check(ok, "laundry: the washer's container row has ZeD's gears button", H.ccKeys())
    local idx = H.ccIdx("obj:ZeDLaundry")
    if not idx then return end
    local c = H.wcontent()
    local z = nil
    for _, hz in ipairs((c and c._hitZones) or {}) do if hz.id == "cc:" .. idx then z = hz end end
    if z then
        c:onMouseDown(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
        c:onMouseUp(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    else
        Q.say("NOTE the gears button has no hit zone this frame: pressed through ContainerControls.press")
        pcall(S.CT.press, c, idx)
    end
end)
Q.waitFor(2, 300, function()
    local e = H.entry()
    return S.washer == nil or (e and e.def.id == "laundry" and e.t and e.t.d ~= nil)
end, function(ok)
    if not S.washer then return end
    local e = H.entry()
    Q.check(e and e.def.id == "laundry" and e.t.obj == S.washer, "laundry: the gears button opens ZeD's laundry card on the washer", tostring(H.kind()))
    local d = e and e.t and e.t.d
    if d then
        local pw = false
        pcall(function() pw = S.washer:getContainer():isPowered() end)
        Q.check(d.on == false and H.pill(e) == ZeD.tr("UI_Off"), "laundry: the card says it is off", tostring(H.pill(e)))
        Q.check(d.powered == (pw and true or false), "laundry: the card reads the power as the game has it", tostring(d.powered) .. " vs " .. tostring(pw))
    end
    RT.bounds(Q, "the laundry card")
    H.closeCard()
end)

-- the fridge: a container in the Loot pane
Q.step(10, function()
    local sq = H.freeSq(S.RING1)
    S.fridge = sq and H.tileObject(sq, { "appliances_refrigeration_01_0", "appliances_refrigeration_01_4" }) or nil
    if S.fridge then
        S.placed[#S.placed + 1] = S.fridge
        H.useSq(sq)
        local inv = S.fridge:getContainerByType("fridge") or S.fridge:getContainer()
        S.fridgeInv = inv
        pcall(function() S.milk = inv:AddItem("Base.Milk") end)
    end
    Q.check(S.fridge ~= nil and S.fridgeInv ~= nil, "fridge: a fridge placed beside the character, milk inside", tostring(sq ~= nil))
    pcall(function() RT.ww()._containersDirty = true end)
end)
Q.waitFor(5, 600, function() return S.fridgeInv == nil or H.inList(S.fridgeInv) ~= nil end, function(ok)
    if not S.fridgeInv then return end
    local ent = H.inList(S.fridgeInv)
    Q.check(ok and ent ~= nil and tostring(ent.name or "") ~= "", "fridge: the World window lists the fridge by name", tostring(ent and ent.name))
    pcall(ZeD_WorldWindow.selectContainer, S.fridgeInv, 60, S.pn)
end)
Q.waitFor(5, 300, function()
    local c = H.wcontent()
    return S.fridgeInv == nil or (c ~= nil and c._inventory == S.fridgeInv and c._flatItems ~= nil and #c._flatItems > 0)
end, function(ok)
    if not S.fridgeInv then return end
    local c = H.wcontent()
    Q.check(c and c._inventory == S.fridgeInv, "fridge: it opens in the Loot pane")
    local seen = false
    for _, it in ipairs((c and c._flatItems) or {}) do if it == S.milk then seen = true end end
    Q.check(seen, "fridge: the pane lists what is inside (the milk)", c and c._flatItems and #c._flatItems)
    RT.bounds(Q, "the fridge in the Loot pane")
end)

-- the stove: the game's stove settings
Q.step(10, function()
    -- (Nov 18 2026: adjacent (RING1): the World window lists only the 3x3 around the character)
    local sq = H.freeSq(S.RING1)
    if not sq then Q.check(false, "stove: a free square beside the character", "none"); return end
    -- (Nov 18 2026: a knob range (PhysPx oven_green: heat and timer knobs, ON and OFF keys), else the red one.
    -- appliances_cooking_01_12 was the modern keypad oven: no heat or timer knob, and its "off" is CANCEL.)
    local tile = nil
    for _, name in ipairs({ "appliances_cooking_01_0", "appliances_cooking_01_8" }) do
        if not tile and getSprite(name) then tile = name end
    end
    if not tile then Q.check(false, "stove: a range placed beside the character", "no knob range sprite"); return end
    local ok = pcall(function()
        S.stove = IsoStove.new(getCell(), sq, getSprite(tile))
        pcall(function() S.stove:createContainersFromSpriteProperties() end)
        sq:AddSpecialObject(S.stove)
        if S.stove:getObjectIndex() < 0 then sq:AddTileObject(S.stove) end
    end)
    if S.stove then S.placed[#S.placed + 1] = S.stove; H.useSq(sq) end
    Q.check(ok and S.stove ~= nil, "stove: a range placed beside the character")
    Q.check(ISOvenUITimedAction and ISOvenUITimedAction._zedHooked == true, "stove: ZeD's hook is on the game's stove settings")
    if S.stove then pcall(function() ISTimedActionQueue.add(ISOvenUITimedAction:new(S.p, S.stove, nil)) end) end
end)
Q.waitFor(5, 600, function()
    if not S.stove then return true end
    local shown = false
    pcall(function() shown = ZeD.TwoWayFull.showingObj(S.pn, S.stove) and true or false end)
    local st = S.ST.current(S.p)
    return shown or (st ~= nil and st.obj == S.stove and RT.ww() ~= nil and RT.ww()._activeTab == "craft")
end, function(ok)
    if not S.stove then return end
    local shown = false
    pcall(function() shown = ZeD.TwoWayFull.showingObj(S.pn, S.stove) and true or false end)
    local st = S.ST.current(S.p)
    Q.check(ok, "stove: the game's stove settings open ZeD's stove (its face popped out, or the Craft tab on it)",
        "face " .. tostring(shown) .. ", station " .. tostring(st and st.kind))
    local e = S.ST.entryFor(S.p, S.stove)
    local words = e and S.ST.stateText(e, S.p)
    local pw, on = false, false
    pcall(function() pw = S.stove:getContainer():isPowered() end)
    pcall(function() on = S.stove:Activated() end)
    local want = (not pw) and ZeD.tr("UI_ZeD_Station_StateNoPower") or (on and getText("UI_On") or getText("UI_Off"))
    Q.check(words ~= nil and words == want, "stove: its state reads as the game has it (power, switch)", tostring(words) .. " (want " .. tostring(want) .. ")")
    RT.bounds(Q, "the stove")
end)
Q.step(5, function()
    pcall(function() if ZeD.TwoWayFull.showingObj(S.pn, S.stove) then ZeD.TwoWayFull.close(S.pn) end end)
    pcall(S.ST.unbind, S.p)
    RT.worldTab("loot")
end)
-- (Nov 18 2026, the ledger's rows on the stove: "Inventory: band scrolls sideways when wide", "Oven / microwave
-- panel (knobs, keys, timer)", "Oven in its own window (pop-out)". Put back by H.stoveBack: the band's offset, the
-- stove's heat, timer and switch, the devices look, the generator stopped, the pop-out closed, the station let go.)
-- the band: the stove shown in the Loot pane, its container row's buttons overflow the list (a stove has many):
-- the right arrow scrolls them sideways (the band's offset, cc.sx.bot), every shown part inside the list; the left
-- arrow scrolls back. Where they all fit (a wide 4K list) that is a SKIP with the width.
function H.bandArrow(cc, left)
    for _, a in ipairs((cc and cc.arrows) or {}) do if (a.idx == -1) == left then return a end end
    return nil
end
function H.bandPress(c, left)
    local a = H.bandArrow(c._cc, left)
    if a then c:onMouseDown(a.x + math.floor(a.w / 2), a.y + math.floor(a.h / 2)) else S.CT.press(c, left and -1 or -2) end
end
Q.step(4, function()
    S.stInv = S.stove and S.stove:getContainer()
    if S.stInv then pcall(ZeD_WorldWindow.selectContainer, S.stInv, 60, S.pn) end
end)
Q.waitFor(4, 300, function()
    local c = H.wcontent()
    return S.stInv == nil or (c ~= nil and c._inventory == S.stInv and c._cc ~= nil and c._cc.strips ~= nil and c._cc.strips.bot ~= nil)
end, function(ok)
    S.bandArm = nil
    if not S.stInv then return end
    local c = H.wcontent()
    if not Q.check(ok, "band: the stove's container row draws its button band") then return end
    if not c._cc.strips.bot.scroll then
        Q.skip("band: the stove's buttons scroll sideways", "they all fit the list's " .. math.floor(c:getWidth()) .. " px here (no overflow)")
        return
    end
    S.bandX0 = c._cc.sx.bot or 0
    S.bandArm = true
    H.bandPress(c, false)
end)
Q.step(3, function()
    if not S.bandArm then return end
    local c = H.wcontent()
    local cc = c._cc
    S.bandX1 = cc.sx.bot or 0
    local bad = 0
    for _, h in ipairs(cc.hits or {}) do if (h.vw or 0) > 0 and (h.vx < -1 or h.vx + h.vw > c:getWidth() + 1) then bad = bad + 1 end end
    Q.check(S.bandX1 > S.bandX0 and bad == 0, "band: its right arrow scrolls the stove's buttons sideways, all inside the list",
        "offset " .. S.bandX0 .. " -> " .. S.bandX1 .. ", " .. bad .. " buttons outside")
    RT.bounds(Q, "the stove's button band")
    H.bandPress(c, true)
end)
Q.step(3, function()
    if not S.bandArm then return end
    local cc = H.wcontent()._cc
    Q.check((cc.sx.bot or 0) < S.bandX1, "band: its left arrow scrolls them back", tostring(cc.sx.bot))
    cc.sx.bot = S.bandX0
end)
-- the panel (StationAppliance): the stove bound in the Craft tab (Stations.open), with power (the grid, else the
-- generator beside it run for the test): a knob's right half (or a key) changes its heat or timer; its timer knob sets
-- the timer; its power key turns it on (the game's own stove command) and off again
function H.stTemp() local v = nil; pcall(function() v = S.stove:getMaxTemperature() end); return v end
function H.stTimer() local v = nil; pcall(function() v = S.stove:getTimer() end); return v end
function H.stOn() local v = false; pcall(function() v = S.stove:Activated() end); return v and true or false end
function H.plate(pred)
    local st = H.craftState()
    for _, z in ipairs((st and st.zones) or {}) do if z.type == "plate" and pred(z) then return z end end
    return nil
end
function H.isHeat(z) return z.kind == "turn" and (z.id == "heat" or z.id == "power") end
function H.isTimer(z) return z.kind == "turn" and z.id == "timer" end
function H.isPowerKey(z) return z.id == "on" or z.id == "onoff" or z.id == "start" end
-- the key that turns it off: OFF first, else the one switch, else a keypad's CANCEL / CLEAR-OFF / STOP
H.OFFKEYS = { "off", "onoff", "cancel", "clearoff", "stop", "start" }
function H.offKeyZone()
    for _, id in ipairs(H.OFFKEYS) do
        local z = H.plate(function(x) return x.id == id end)
        if z then return z end
    end
    return nil
end
function H.rightHalf(z) return pcall(ZeD.CraftingTab.onClick, RT.ww(), z.x + math.floor(z.w * 3 / 4), z.y + math.floor(z.h / 2)) end
Q.step(4, function()
    S.stBack = { temp = H.stTemp(), timer = H.stTimer(), on = H.stOn(), dev = ZeD.Settings.lookStyleOption and ZeD.Settings.lookStyleOption:getValue() }
    local pw = false
    pcall(function() pw = S.stInv:isPowered() end)
    if not pw and S.gen then
        pcall(function() S.gen:setConnected(true); S.gen:setFuel(60); S.gen:setActivated(true) end)
        S.genForStove = true
    end
end)
Q.waitFor(4, 600, function() local pw = false; pcall(function() pw = S.stInv:isPowered() end); return S.stInv == nil or pw end, function(ok)
    S.stArm = nil
    if not S.stInv then return end
    S.stArm = Q.check(ok, "oven: the stove has power (the grid, or the generator beside it run for the test)")
    if S.stArm then pcall(S.ST.open, S.p, S.stove) end
end)
Q.waitFor(4, 300, function()
    if not S.stArm then return true end
    local st = S.ST.current(S.p)
    return st ~= nil and st.obj == S.stove and RT.ww()._activeTab == "craft" and H.plate(function() return true end) ~= nil
end, function(ok)
    if not S.stArm then return end
    if not Q.check(ok, "oven: the stove is bound in the Craft tab, its panel's controls drawn") then S.stArm = nil; return end
    S.t0, S.tm0 = H.stTemp(), H.stTimer()
    local z = H.plate(H.isHeat) or H.plate(H.isTimer) or H.plate(function(x) return x.id == "up" end)
    S.stCtl = z and z.id
    if z then H.rightHalf(z) end
end)
Q.step(4, function()
    if not S.stArm then return end
    Q.check(S.stCtl ~= nil and (H.stTemp() ~= S.t0 or H.stTimer() ~= S.tm0), "oven: a knob or key on its panel changes the stove's setting",
        tostring(S.stCtl) .. ": heat " .. tostring(S.t0) .. " -> " .. tostring(H.stTemp()) .. ", timer " .. tostring(S.tm0) .. " -> " .. tostring(H.stTimer()))
    local zt = H.plate(H.isTimer)
    S.tm1 = H.stTimer()
    if zt then H.rightHalf(zt) else Q.skip("oven: the timer knob sets the timer", "this stove's panel has no timer knob (" .. tostring(S.stCtl) .. ")") end
    S.stTimerZ = zt ~= nil
end)
Q.step(4, function()
    if not (S.stArm and S.stTimerZ) then return end
    Q.check(H.stTimer() ~= S.tm1 and (H.stTimer() or 0) > 0, "oven: its timer knob sets the timer", tostring(S.tm1) .. " -> " .. tostring(H.stTimer()))
end)
Q.step(2, function()
    if not S.stArm then return end
    local z = H.plate(H.isPowerKey)
    S.stKey = z and z.id
    if not z then Q.skip("oven: its power key turns it on", "this stove's panel has no on key (a keypad oven starts from its keys)"); return end
    pcall(ZeD.CraftingTab.onClick, RT.ww(), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
end)
Q.waitFor(4, 600, function() return not (S.stArm and S.stKey) or H.stOn() end, function(ok)
    if not (S.stArm and S.stKey) then return end
    Q.check(ok, "oven: its power key turns the stove on (the game's stove command)", tostring(S.stKey))
    local z = H.offKeyZone()
    if z then pcall(ZeD.CraftingTab.onClick, RT.ww(), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)) end
end)
Q.waitFor(4, 600, function() return not (S.stArm and S.stKey) or not H.stOn() end, function(ok)
    if not (S.stArm and S.stKey) then return end
    Q.check(ok, "oven: pressed again it turns off")
end)
-- the pop-out (StationPopout, with ZeD setup's Devices on Simple: with faces on the button pops the face out
-- instead): the panel's pop-out button opens the stove in its own window, centred and on screen; the tab's "bring it
-- back" closes it; popped out again, letting the station go closes it too
function H.spWin() local w = nil; pcall(function() w = ZeD.StationPopout.get(S.pn) end); return w end
function H.spUp() local w = H.spWin(); return w ~= nil and w:isReallyVisible() end
function H.craftPress(kind)
    local z = H.craftZone(kind)
    if z then H.craftClick(z) end
    return z ~= nil
end
Q.step(4, function()
    if not S.stArm then return end
    pcall(function() ZeD.Settings.lookStyleOption:setValue(2) end)
end)
Q.waitFor(4, 300, function() return not S.stArm or H.craftZone("popout") ~= nil end, function(ok)
    if not S.stArm then return end
    S.spArm = Q.check(ok, "pop-out: the stove's panel (Simple) has its pop-out button")
    if S.spArm then H.craftPress("popout") end
end)
Q.waitFor(2, 120, function() return not S.spArm or H.spUp() end, function(ok)
    if not S.spArm then return end
    local w = H.spWin()
    local W = getCore():getScreenWidth()
    local mid = w and (w:getX() + w:getWidth() / 2) or -1
    Q.check(ok and w.st ~= nil and w.st.obj == S.stove and math.abs(mid - W / 2) <= 2, "pop-out: the stove opens in its own window, centred",
        "up " .. tostring(ok) .. ", middle " .. math.floor(mid) .. " of " .. W)
    RT.bounds(Q, "the stove's own window")
end)
Q.waitFor(2, 120, function() return not S.spArm or H.craftZone("popin") ~= nil end, function(ok)
    if not S.spArm then return end
    if ok then H.craftPress("popin") else pcall(function() ZeD.StationPopout.close(S.p) end) end
    S.spIn = ok
end)
Q.waitFor(2, 120, function() return not S.spArm or not H.spUp() end, function(ok)
    if not S.spArm then return end
    Q.check(S.spIn and ok, "pop-out: the tab's bring-it-back closes the stove's window")
end)
Q.waitFor(2, 120, function() return not S.spArm or H.craftZone("popout") ~= nil end, function(ok)
    if not S.spArm then return end
    if ok then H.craftPress("popout") end
end)
Q.waitFor(2, 120, function() return not S.spArm or H.spUp() end, function(ok)
    if not S.spArm then return end
    S.spAgain = ok
    pcall(S.ST.unbind, S.p)
end)
Q.waitFor(2, 300, function() return not S.spArm or not H.spUp() end, function(ok)
    if not S.spArm then return end
    Q.check(S.spAgain and ok, "pop-out: letting the station go closes its window", "opened again " .. tostring(S.spAgain))
end)
Q.step(2, function() H.stoveBack() end)
function H.stoveBack()
    pcall(function() if H.spUp() then ZeD.StationPopout.close(S.p) end end)
    local b = S.stBack
    if b then
        S.stBack = nil
        pcall(function() if b.dev then ZeD.Settings.lookStyleOption:setValue(b.dev) end end)
        pcall(function() if H.stOn() ~= b.on then ZeD.StationAppliance.toggle(S.p, { obj = S.stove }, 0) end end)
        pcall(function() if b.temp then S.stove:setMaxTemperature(b.temp) end end)
        pcall(function() if b.timer then S.stove:setTimer(b.timer) end end)
    end
    pcall(function() local cc = H.wcontent()._cc; if S.bandX0 and cc then cc.sx.bot = S.bandX0 end end)
    if S.genForStove then
        S.genForStove = nil
        pcall(function() S.gen:setActivated(false); S.gen:setConnected(false) end)
    end
    pcall(S.ST.unbind, S.p)
    RT.worldTab("loot")
end

-- ===================================================================== stations
Q.step(20, function()
    if not (ISBuildIsoEntity and SpriteConfigManager and ISEntityUI and ISEntityUI.OpenWindow) then
        Q.check(false, "station: the game's build and station code is loaded"); return
    end
    local objs, why = H.build("Base.Kiln_Small")
    if not objs then Q.check(false, "station: a Primitive Kiln built beside the character", why); return end
    for _, o in ipairs(objs) do
        local m = S.ST.call(o, "getMasterObject") or o
        if not S.kiln and S.ST.classify(m, true) == "bench" then S.kiln = m end
    end
    Q.check(S.kiln ~= nil, "station: a Primitive Kiln built beside the character (a craft bench)", #objs .. " objects")
end)
Q.step(10, function()
    if not S.kiln then return end
    local ok, err = pcall(ISEntityUI.OpenWindow, S.p, S.kiln)
    if not ok then Q.say("NOTE ISEntityUI.OpenWindow: " .. tostring(err)) end
end)
Q.waitFor(5, 600, function()
    if not S.kiln then return true end
    local st = S.ST.current(S.p)
    return st ~= nil and st.obj == S.kiln and RT.ww() ~= nil and RT.ww()._activeTab == "craft"
end, function(ok)
    if not S.kiln then return end
    local st = S.ST.current(S.p)
    Q.check(ok, "station: the game's station option binds the kiln in the World window's Craft tab", tostring(st and st.name))
    if st then
        local words = S.ST.stateText(st, S.p)
        Q.check(st.kind == "bench" and words == ZeD.tr("UI_ZeD_Station_StateInUseByYou"), "station: the kiln reads in use by you", tostring(words))
        local u = nil
        pcall(function() u = S.kiln:getUsingPlayer() end)
        Q.check(u == S.p, "station: the kiln holds the game's one-player lock for you")
    end
    RT.bounds(Q, "the kiln in the Craft tab")
    H.closeGameStationWindows()
end)
Q.step(5, function()
    pcall(S.ST.unbind, S.p)
    RT.worldTab("loot")
    Q.skip("a mod's general station card (StationGeneral.lua)", "no mod station is installed on the release-test save")
end)

-- ===================================================================== a drying rack (StationMachine)
-- (Nov 18 2026, the ledger's row "Drying rack / machine (slots, Start, Take all, Add)": a herb drying rack built beside
-- the character (the game's build code, as the kiln), two basil carried; the game's station option binds it in the
-- Craft tab's machine view; Add (zone mAdd) puts the basil in its input slots (the game's ISItemSlotAddAction); Start
-- (mStart) runs it when the game's canStart allows; pressed again it stops; a slot's take (mInRemove) brings the basil
-- back out. Take all (mTakeAll) empties the OUTPUT, which fills only after the drying's 24 game hours: it is checked
-- only when the rack shows it. The rack goes in the put-back.)
function H.rackComp() local st = S.ST.current(S.p); return (st and st.obj == S.rack) and st.comp or nil end
function H.rackRunning() local v = false; pcall(function() v = H.rackComp():isRunning() end); return v and true or false end
function H.basilIn() local n = 0; pcall(function() n = S.p:getInventory():getCountTypeRecurse("Base.Basil") end); return n end
Q.step(10, function()
    S.rack = nil
    -- (Nov 18 2026, Build: ZeD's Add mirrors the game's ISCraftLogicPanel.ItemSlotAddItems, a walk then the slot
    -- action; built 4-5 tiles off (S.BUILD) the walk ran past its 3-tile reach in a crowded site. Within 3 tiles now.)
    local near = {}
    for _, o in ipairs(S.RING1) do near[#near + 1] = o end
    for _, o in ipairs(S.RING2) do near[#near + 1] = o end
    local objs, why = H.build("Base.Herb_Drying_Rack", near)
    for _, o in ipairs(objs or {}) do
        local m = S.ST.call(o, "getMasterObject") or o
        if not S.rack and S.ST.classify(m, true) == "machine" then S.rack = m end
    end
    if not Q.check(S.rack ~= nil, "rack: a herb drying rack built beside the character", tostring(why or (objs and #objs .. " objects"))) then return end
    S.basil = { RT.give("Base.Basil"), RT.give("Base.Basil") }
    S.basil0 = H.basilIn()
    pcall(ISEntityUI.OpenWindow, S.p, S.rack)
end)
Q.waitFor(5, 600, function()
    if not S.rack then return true end
    return H.rackComp() ~= nil and RT.ww()._activeTab == "craft" and H.craftZone("mAdd") ~= nil
end, function(ok)
    S.rkArm = nil
    if not S.rack then return end
    H.closeGameStationWindows()
    S.rkArm = Q.check(ok, "rack: bound in the Craft tab, its Add offers the basil carried")
    if S.rkArm then H.craftPress("mAdd") end
end)
-- (one frame after Add: what the game queued, and the room the rack has)
Q.step(1, function()
    if not S.rkArm then return end
    local comp = H.rackComp()
    local outFree = comp and S.ST.call(comp, "getFreeOutputSlotCount")
    local dist = "?"
    pcall(function()
        local rs = S.rack:getSquare()
        if rs then
            local dx, dy = rs:getX() + 0.5 - S.p:getX(), rs:getY() + 0.5 - S.p:getY()
            dist = string.format("%.1f", math.sqrt(dx * dx + dy * dy))
        end
    end)
    Q.say("NOTE rack Add: queue " .. H.queueTypes() .. ", free output slots " .. tostring(outFree) .. ", distance " .. dist .. ", basil " .. H.basilIn())
end)
Q.waitFor(4, 1800, function() return not S.rkArm or (H.basilIn() < S.basil0 and H.queueTypes() == "none") end, function(ok)
    if not S.rkArm then return end
    Q.check(ok, "rack: Add puts the basil into its input slots (the game's slot action)", S.basil0 .. " -> " .. H.basilIn() .. " carried")
end)
-- (Nov 18 2026, r7: the slots are checked BEFORE Start: a running rack holds its input as "drying", which shows no
-- take. The basil taken goes back in with Add, then Start. Stopping is queued after a walk to the rack (SM.stop, as
-- Add), so the stop is read once the timed-action queue is empty.)
Q.waitFor(4, 300, function() return not S.rkArm or H.craftZone("mInRemove") ~= nil end, function(ok)
    if not S.rkArm then return end
    S.rkIn = H.basilIn()
    if Q.check(ok, "rack: its input slots show the basil to take") then H.craftPress("mInRemove") end
    if H.craftZone("mTakeAll") then
        Q.say("NOTE the rack shows an output to take: Take all pressed")
        S.rkTakeAll = true
        H.craftPress("mTakeAll")
    else
        Q.skip("rack: Take all empties the output", "nothing has dried (the drying takes 24 game hours); a slot's take is checked instead")
    end
end)
Q.waitFor(4, 1800, function() return not S.rkArm or (H.basilIn() > S.rkIn and H.queueTypes() == "none") end, function(ok)
    if not S.rkArm then return end
    Q.check(ok, "rack: a slot's take brings the basil back out (the game's slot action)", S.rkIn .. " -> " .. H.basilIn() .. " carried")
end)
-- the basil taken goes back in for Start (Add again)
Q.waitFor(4, 300, function() return not S.rkArm or H.craftZone("mAdd") ~= nil end, function(ok)
    if not S.rkArm then return end
    S.rkBack = H.basilIn()
    S.rkReAdd = ok and H.craftPress("mAdd") or false
    if not S.rkReAdd then Q.say("NOTE rack: no Add drawn after the take (basil " .. S.rkBack .. ")") end
end)
Q.waitFor(4, 1800, function() return not (S.rkArm and S.rkReAdd) or (H.basilIn() < S.rkBack and H.queueTypes() == "none") end, function(ok)
    if not (S.rkArm and S.rkReAdd) then return end
    if not ok then Q.say("NOTE rack: the basil did not go back in (" .. S.rkBack .. " -> " .. H.basilIn() .. ", queue " .. H.queueTypes() .. ")") end
end)
Q.waitFor(4, 300, function() local z = H.craftZone("mStart"); return not S.rkArm or z ~= nil end, function(ok)
    if not S.rkArm then return end
    local z = H.craftZone("mStart")
    S.rkStart = z and z.enabled
    if not z then Q.check(false, "rack: its Start is drawn"); return end
    if not z.enabled then Q.skip("rack: Start runs it", "the game's canStart says no for this load"); return end
    H.craftClick(z)
end)
-- (Nov 18 2026, diagnostics for the Stop step: does the queued ISGenericCraftStart(stop) pass isValid? It asks
-- entity:isUsingPlayer(character) first. isValid and perform are wrapped only around the Stop press and the game's
-- own Cancel below, and unwrapped right after (and in the put-back). NOTE lines only.)
function H.rkUse(obj, who)
    local u, g = nil, nil
    pcall(function() u = obj:isUsingPlayer(who) end)
    pcall(function() g = obj:getUsingPlayer() end)
    return "isUsingPlayer " .. tostring(u) .. " (getUsingPlayer " .. ((g == nil) and "nil" or ((g == who) and "you" or "someone else")) .. ")"
end
function H.rkUseNow()
    local st = S.ST.current(S.p)
    local obj = (st and st.obj) or S.rack
    return H.rkUse(obj, S.p) .. ((st and st.obj) and "" or " [no ZeD binding, read on the rack]")
end
function H.rkCan(a)
    local ok, r = pcall(a.funcCanStart, a.character, a.entity, a.component)
    return ok and tostring(r) or ("error " .. tostring(r))
end
function H.rkReq(c)
    local r = nil
    pcall(function() r = c:isStopRequested() end)
    return tostring(r)
end
function H.rkWrap(tag)
    if S.rkOrigV or not ISGenericCraftStart then return end
    local origV, origP = ISGenericCraftStart.isValid, ISGenericCraftStart.perform
    S.rkOrigV, S.rkOrigP, S.rkTag = origV, origP, tag
    S.rkNV, S.rkNP, S.rkLastV = 0, 0, nil
    ISGenericCraftStart.isValid = function(self)
        local r = origV(self)
        S.rkNV = (S.rkNV or 0) + 1
        if S.rkNV <= 2 or r ~= S.rkLastV then
            Q.say("NOTE rack stop (" .. tostring(S.rkTag) .. "): isValid ran (call " .. S.rkNV .. ") -> " .. tostring(r)
                .. ", funcCanStart " .. H.rkCan(self) .. ", " .. H.rkUse(self.entity, self.character))
        end
        S.rkLastV = r
        return r
    end
    ISGenericCraftStart.perform = function(self)
        S.rkNP = (S.rkNP or 0) + 1
        local before = H.rkReq(self.component)
        Q.say("NOTE rack stop (" .. tostring(S.rkTag) .. "): perform ran, funcCanStart " .. H.rkCan(self) .. ", "
            .. H.rkUse(self.entity, self.character) .. ", isStopRequested before " .. before)
        local ok, err = pcall(origP, self)
        Q.say("NOTE rack stop (" .. tostring(S.rkTag) .. "): perform done" .. (ok and "" or (" with error " .. tostring(err)))
            .. ", isStopRequested after " .. H.rkReq(self.component))
        if not ok then error(err) end
    end
end
function H.rkUnwrap()
    if not S.rkOrigV then return end
    Q.say("NOTE rack stop (" .. tostring(S.rkTag) .. "): unwrapped; isValid ran " .. tostring(S.rkNV) .. " times, perform " .. tostring(S.rkNP) .. " times")
    ISGenericCraftStart.isValid, ISGenericCraftStart.perform = S.rkOrigV, S.rkOrigP
    S.rkOrigV, S.rkOrigP = nil, nil
end
Q.waitFor(4, 900, function() return not (S.rkArm and S.rkStart) or H.rackRunning() end, function(ok)
    if not (S.rkArm and S.rkStart) then return end
    Q.check(ok, "rack: Start runs it (isRunning)")
    S.rkStopAt = getTimestampMs()
    local z = H.craftZone("mStart")
    Q.say("NOTE rack stop: at the press, " .. H.rkUseNow() .. ", isStopRequested " .. H.rkReq(H.rackComp())
        .. ", isRunning " .. tostring(H.rackRunning()) .. ", Start zone " .. tostring(z ~= nil) .. " running " .. tostring(z and z.running))
    H.rkWrap("ZeD Stop")
    -- (run 9: the drawn flag z.running lags the live state by up to 20 frames, so pressing only on it skipped the
    -- press; the press goes in whenever the rack is live-running, as a player's would.)
    if z and H.rackRunning() then H.craftClick(z) end
    Q.say("NOTE rack stop: just after the press, queue " .. H.queueTypes() .. ", " .. H.rkUseNow() .. ", isStopRequested " .. H.rkReq(H.rackComp()))
end)
-- (the stop walks to the rack first: wait for the queue to empty, at least half a second after the press)
Q.waitFor(4, 1800, function()
    if not (S.rkArm and S.rkStart) then return true end
    return getTimestampMs() - (S.rkStopAt or 0) >= 500 and H.queueTypes() == "none"
end, function(okq)
    if not (S.rkArm and S.rkStart) then return end
    if not okq then Q.say("NOTE rack stop: the queue did not empty: " .. H.queueTypes()) end
end)
-- (Nov 18 2026, Build: ZeD's Stop does what the game's own Cancel does (component:stop(player)); CraftLogic.stop
-- sets a stop request handled on the logic's update, and DryingCraftLogic's own isRunning may stay true while anything
-- sits drying. So the check is that the stop request is taken: isStopRequested or not running. (Run 9: DryingCraftLogic has no isCancelled; asking each frame logged 185 exceptions, so it is not asked.))
function H.rackFlags()
    local c = H.rackComp()
    local run, req, can = nil, nil, nil
    pcall(function() run = c:isRunning() end)
    pcall(function() req = c:isStopRequested() end)
    return run, req, can
end
Q.waitFor(1, 180, function()
    if not (S.rkArm and S.rkStart) then return true end
    local run, req, can = H.rackFlags()
    return run == false or req == true or can == true
end, function(ok)
    if not (S.rkArm and S.rkStart) then return end
    local run, req, can = H.rackFlags()
    Q.check(ok, "rack: Start pressed again stops it (its stop request is taken)",
        "isRunning " .. tostring(run) .. ", isStopRequested " .. tostring(req) .. ", queue " .. H.queueTypes())
    Q.say("NOTE rack stop: at the check, " .. H.rkUseNow())
    H.rkUnwrap()
end)
-- (Nov 18 2026, diagnostics: the same stop through the game's own Cancel (ISWidgetCraftLogicControl:cancelCraft) in
-- the game's own window, safe mode on for it and put back exactly as found after. NOTE lines and SKIPs only.)
function H.rkFlagsOf(c)
    local run, req, can = nil, nil, nil
    pcall(function() run = c:isRunning() end)
    pcall(function() req = c:isStopRequested() end)
    return "isRunning " .. tostring(run) .. ", isStopRequested " .. tostring(req)
end
function H.rkFindCancel(el, depth)
    if not el or depth > 14 then return nil end
    if el.cancelCraft and el.logic then return el end
    for _, ch in pairs(el.children or {}) do
        local f = H.rkFindCancel(ch, depth + 1)
        if f then return f end
    end
    return nil
end
function H.rkGameCancel()
    local found = nil
    pcall(function()
        local pl = ISEntityUI.players and ISEntityUI.players[S.pn]
        for _, w in pairs((pl and pl.windows) or {}) do
            if not found and w and w.instance then found = H.rkFindCancel(w.instance, 0) end
        end
    end)
    return found
end
function H.rkCmpBack()
    H.rkUnwrap()
    if S.rkSafeSet then
        S.rkSafeSet = false
        H.closeGameStationWindows()
        pcall(function() ZeD.Settings.safeModeOption:setValue(S.rkSafeVal) end)
        pcall(function() ZeD.Safe.reread() end)
        Q.say("NOTE rack Cancel: safe mode option put back to " .. tostring(S.rkSafeVal) .. ", ZeD.Safe.on() " .. tostring(ZeD.Safe.on()))
    end
end
Q.step(2, function()
    S.rkCmp = false
    if not (S.rkArm and S.rkStart) then return end
    S.rkC = H.rackComp()
    if not S.rkC then Q.skip("NOTE rack Cancel comparison", "no rack component bound"); return end
    S.rkCmp = true
    S.rkRestart = false
    if not H.rackRunning() then
        local z = H.craftZone("mStart")
        if z and z.enabled and not z.running then
            S.rkRestart = true
            H.craftClick(z)
            Q.say("NOTE rack Cancel: the first stop stopped it; Start pressed again before the comparison")
        end
    end
end)
Q.waitFor(4, 900, function() return not S.rkCmp or H.rackRunning() end, function(ok)
    if not S.rkCmp then return end
    Q.say("NOTE rack Cancel: before the comparison, " .. H.rkFlagsOf(S.rkC) .. ", queue " .. H.queueTypes() .. ", restarted " .. tostring(S.rkRestart))
    if not ok then
        S.rkCmp = false
        Q.skip("NOTE rack Cancel comparison", "the rack is not running, so the game's Cancel button would do nothing")
        return
    end
    local opt, Sf = ZeD.Settings and ZeD.Settings.safeModeOption, ZeD.Safe
    if not (opt and Sf and Sf.reread) then
        S.rkCmp = false
        Q.skip("NOTE rack Cancel comparison", "no safe mode option or ZeD.Safe.reread to hand the window to the game")
        return
    end
    local okv, v = pcall(function() return opt:getValue() end)
    if not okv or Sf.on() then
        S.rkCmp = false
        Q.skip("NOTE rack Cancel comparison", "safe mode already on or its option unreadable (" .. tostring(v) .. ")")
        return
    end
    H.stopActions()
    S.rkSafeVal, S.rkSafeSet = v, true
    opt:setValue(2)
    Sf.reread()
    Q.say("NOTE rack Cancel: safe mode on (was " .. tostring(v) .. "), ZeD.Safe.on() " .. tostring(Sf.on()) .. ", " .. H.rkUseNow())
    pcall(ISEntityUI.OpenWindow, S.p, S.rack)
end)
Q.waitFor(4, 300, function() return not S.rkCmp or H.rkGameCancel() ~= nil end, function(ok)
    if not S.rkCmp then return end
    local w = H.rkGameCancel()
    if not (ok and w) then
        S.rkCmp = false
        Q.skip("NOTE rack Cancel comparison", "the game's window for the rack has no craft logic control (cancelCraft) to press")
        H.rkCmpBack()
        return
    end
    local lc = nil
    pcall(function() lc = w.logic:getCraftLogic() end)
    if lc then S.rkC = lc end
    Q.say("NOTE rack Cancel: the game's window is open, " .. H.rkUse(S.rack, S.p) .. ", " .. H.rkFlagsOf(S.rkC)
        .. ", same component as ZeD's " .. tostring(lc == H.rackComp()))
    local run = false
    pcall(function() run = w.logic:getCraftLogic():isRunning() end)
    if not run then
        S.rkCmp = false
        Q.skip("NOTE rack Cancel comparison", "the game's window reads the rack not running: its Cancel button would do nothing")
        H.rkCmpBack()
        return
    end
    H.rkWrap("game Cancel")
    local okc, err = pcall(function() w:cancelCraft() end)
    S.rkCancelAt = getTimestampMs()
    Q.say("NOTE rack Cancel: cancelCraft called" .. (okc and "" or (" with error " .. tostring(err))) .. ", queue " .. H.queueTypes())
end)
Q.waitFor(4, 1800, function()
    if not S.rkCmp then return true end
    return getTimestampMs() - (S.rkCancelAt or 0) >= 500 and H.queueTypes() == "none"
end, function(okq)
    if not S.rkCmp then return end
    Q.say("NOTE rack Cancel: queue " .. (okq and "empty" or ("not empty: " .. H.queueTypes())) .. ", after the game's Cancel "
        .. H.rkFlagsOf(S.rkC) .. ", " .. H.rkUse(S.rack, S.p))
    H.rkCmpBack()
end)
Q.step(5, function()
    if not S.rkArm then return end
    pcall(H.rkCmpBack)
    if S.rkC then Q.say("NOTE rack Cancel: with ZeD back, " .. H.rkFlagsOf(S.rkC) .. ", ZeD.Safe.on() " .. tostring(ZeD.Safe and ZeD.Safe.on())) end
    RT.pairOpen()
end)
Q.step(2, function()
    if not S.rkArm then return end
    H.stopActions()
    pcall(S.ST.unbind, S.p)
    RT.worldTab("loot")
end)

-- ===================================================================== the ledger's rows (FEATURE_MAP.md, Check "rt_cards")
-- (Nov 18 2026, QA's ledger pass: a row is covered only by a check that measures it. These are the rows the ledger
-- gave this script that nothing above measured. Put back by H.ledgerBack.)
function H.stripZone(strip, id)
    for _, z in ipairs((strip and strip._hitZones) or {}) do if z.id == id then return z end end
    return nil
end
function H.press(strip, id)
    local z = H.stripZone(strip, id)
    if not z then return false end
    strip:onMouseDown(z.x + 2, z.y + 2)
    return true
end
-- the tab strips' own press (strip.onMouseDown): a tab switches, the same tab again folds back to Loot, and Loot snaps
-- the Character window to the inventory alone (strip, list, strip wide, its right edge where it was anchored)
Q.step(5, function()
    RT.pairOpen()
    H.closeCard()
    RT.charTab("loot")
    RT.worldTab("loot")
end)
Q.step(6, function() S.tsA = H.press(RT.charStrip(), "tab:skills") end)
Q.step(6, function()
    local w = RT.cw()
    Q.check(S.tsA and w._activeTab == "skills" and w._drawerOpen == true, "tab strip (Character window): a press on Skills opens it",
        "tab " .. tostring(w._activeTab))
    S.tsB = H.press(RT.charStrip(), "tab:skills")
end)
Q.waitFor(2, 120, function() local w = RT.cw(); return w._activeTab == "loot" and w._drawerOpen == false end, function(ok)
    Q.check(S.tsB and ok, "tab strip (Character window): Skills pressed again folds back to Loot", "tab " .. tostring(RT.cw()._activeTab))
end)
function H.snapW(w) local T = ZeD.T; return T.px(36) + T.px(w._baseInvW or 0) + T.px(36) end
Q.waitFor(2, 300, function() local w = RT.cw(); return w._baseInvW ~= nil and math.abs(w:getWidth() - H.snapW(w)) <= 1 end, function(ok)
    local w = RT.cw()
    local edge = w._anchorRightEdge
    Q.check(ok and (edge == nil or math.abs(w:getX() + w:getWidth() - edge) <= 1),
        "Loot snaps the Character window to the inventory alone, its right edge kept",
        math.floor(w:getWidth()) .. " wide, want " .. H.snapW(w) .. "; right " .. math.floor(w:getX() + w:getWidth()) .. ", anchor " .. tostring(edge))
end)
Q.step(2, function()
    local w = RT.cw()
    S.tso = w._tabScrollOffset or 0
    if not H.stripZone(RT.charStrip(), "tab_scroll_down") then
        S.tso = nil
        Q.skip("tab strip scroll arrows", "the strip shows every tab at this size (no overflow, no arrows)")
        return
    end
    H.press(RT.charStrip(), "tab_scroll_down")
    Q.check((w._tabScrollOffset or 0) ~= S.tso, "tab strip: the scroll arrow moves the tabs by a row",
        S.tso .. " -> " .. tostring(w._tabScrollOffset))
end)
Q.step(4, function()
    if S.tso == nil then return end
    H.press(RT.charStrip(), "tab_scroll_up")
    local w = RT.cw()
    Q.check((w._tabScrollOffset or 0) == S.tso, "tab strip: the other arrow moves them back", tostring(w._tabScrollOffset))
    w._tabScrollOffset = S.tso
end)
Q.step(4, function() S.wsA = H.press(RT.worldStrip(), "tab:craft") end)
Q.step(6, function()
    Q.check(S.wsA and ZeD_WorldWindow.isTabShowing("craft", S.pn), "tab strip (World window): a press on Craft opens it",
        "tab " .. tostring(RT.ww()._activeTab))
    S.wsB = H.press(RT.worldStrip(), "tab:craft")
end)
Q.waitFor(2, 120, function() return RT.ww()._activeTab == "loot" end, function(ok)
    Q.check(S.wsB and ok, "tab strip (World window): Craft pressed again folds back to Loot", "tab " .. tostring(RT.ww()._activeTab))
end)
-- the halves roll up after two seconds away (WindowHalves.update): the drawer half unpinned, on Skills, the pointer
-- off both windows (getMouseX / getMouseY answer a spot beside them for the wait); the folded drawer keeps its tab.
-- Put back: the pointer, the pin, the half shown.
function H.overWin(x, y)
    for _, w in ipairs({ RT.cw(), RT.ww() }) do
        if w and x >= w:getAbsoluteX() - 4 and y >= w:getAbsoluteY() - 4 and x <= w:getAbsoluteX() + w:getWidth() + 4
            and y <= w:getAbsoluteY() + w:getHeight() + 4 then return true end
    end
    return false
end
function H.mouseBack()
    if S.mouseWas then getMouseX, getMouseY = S.mouseWas[1], S.mouseWas[2]; S.mouseWas = nil end
end
-- (Nov 18 2026: an item card left open from an earlier step kept the drawer on "item", and only a tab drawer rolls
-- (WindowHalves drawerOpen): the cards are closed first, and the drawer must be on its tab before the wait. A pad
-- joined holds every timer (WindowHalves.update), so that is a SKIP. Where the list hides under a full drawer (the
-- Deck), H.drive shades the whole window instead of folding the drawer: the tab is then the window's own.)
S.HV_ROLL = "halves: the unpinned drawer rolls up after 2 s with the pointer away"
S.HV_TAB = "halves: the rolled drawer keeps its tab (Skills)"
Q.step(4, function()
    S.hv = nil
    local w, Hv = RT.cw(), ZeD.Halves
    if not (w and Hv and w._halves) then Q.check(false, "halves: the Character window has its halves"); return end
    local pad = JoypadState and JoypadState.players and JoypadState.players[S.pn + 1] ~= nil
    if pad then
        Q.skip(S.HV_ROLL, "a controller is joined: the halves hold while a pad plays")
        Q.skip(S.HV_TAB, "a controller is joined")
        return
    end
    local W, Hs = getCore():getScreenWidth(), getCore():getScreenHeight()
    local spot = nil
    -- (Nov 18 2026, r7: the spot is the middle-top of the screen, off both windows; where they cover it, a step down
    -- the screen at a time until a spot is off both. The bottom-right corner it used before may sit on an edge zone.)
    local mx, sy = math.floor(W / 2), 24
    while not spot and sy < Hs - 4 do
        if not H.overWin(mx, sy) then spot = { mx, sy } end
        sy = sy + 16
    end
    if not spot then Q.skip("halves roll up after 2 s away", "the windows cover the screen's middle column top to bottom"); return end
    -- no card in the drawer (nothing selected in the list), no object card
    H.closeCard()
    local c = H.content()
    if c and w._drawerItem and w._updateDrawer then
        c._selectedItems = {}
        c._lastClickedItem = nil
        pcall(w._updateDrawer, c)
    end
    S.hv = { pin = w._halves.drawer.pinned == true, spot = spot }
    RT.charTab("skills")
    pcall(Hv.setPin, w, "drawer", false)
end)
Q.waitFor(2, 120, function()
    local w = RT.cw()
    return S.hv == nil or (w._drawerMode == "tab" and w._drawerOpen == true and w._activeTab == "skills")
end, function(ok)
    if not S.hv then return end
    local w = RT.cw()
    if not ok then
        local why = "before the wait the drawer was not on Skills: mode " .. tostring(w._drawerMode) .. ", tab " .. tostring(w._activeTab)
        Q.check(false, S.HV_ROLL, why)
        Q.check(false, S.HV_TAB, why)
        H.halvesBack()
        return
    end
    local spot = S.hv.spot
    S.mouseWas = { getMouseX, getMouseY }
    getMouseX = function() return spot[1] end
    getMouseY = function() return spot[2] end
    S.hvT0 = getTimestampMs()
end)
Q.waitFor(2, 900, function() local w = RT.cw(); return S.hv == nil or w._halves.drawer.rolled == true end, function(ok)
    if not S.hv then return end
    local w = RT.cw()
    local ms = getTimestampMs() - S.hvT0
    -- (read while getMouseX / getMouseY still answer the spot, as WindowHalves.update saw it)
    Q.say("NOTE halves at the wait's end: " .. H.hvDiag(w))
    H.mouseBack()
    Q.check(ok and ms >= 1500, S.HV_ROLL, ms .. " ms" .. (w.windowShaded and " (the whole window shaded: its list hid under the drawer)" or ""))
    local tab = ZeD.Halves.foldedTab(w)
    local kept = tab == "skills" or (tab == nil and w.windowShaded and w._activeTab == "skills")
    Q.check(kept, S.HV_TAB, "folded " .. tostring(tab) .. ", shaded " .. tostring(w.windowShaded) .. ", tab " .. tostring(w._activeTab))
    H.halvesBack()
end)
-- (Nov 18 2026, Build: the Deck's roll-up was not settled from the code; what holds the timer, for the window timed)
function H.hvDiag(w)
    local out = {}
    local function add(k, f)
        local ok, v = pcall(f)
        out[#out + 1] = k .. "=" .. (ok and tostring(v) or "err")
    end
    local now = getTimestampMs()
    add("pad", function() return JoypadState ~= nil and JoypadState.players ~= nil and JoypadState.players[S.pn + 1] ~= nil end)
    for _, pr in ipairs({ { "cw", RT.cw() }, { "ww", RT.ww() } }) do
        local win = pr[2]
        local d = nil
        if win then pcall(function() d = win._mainContent and win._mainContent._drag end) end
        add(pr[1] .. ".drag", function() return d end)
        add(pr[1] .. ".dragActive", function()
            if type(d) == "table" and type(d.isActive) == "function" then return d:isActive() end
            return "n/a"
        end)
    end
    if not w then return table.concat(out, ", ") .. ", window nil" end
    add("moving", function() return w.moving end)
    add("pinned", function() return w.pinned end)
    add("outSince-now", function() return (type(w._outSince) == "number") and (w._outSince - now) or tostring(w._outSince) end)
    add("halves", function() return w._halves end)
    add("halves.drawer", function() return w._halves and w._halves.drawer end)
    add("drawer.out", function() return w._halves and w._halves.drawer and w._halves.drawer.out end)
    add("drawer.rolled", function() return w._halves and w._halves.drawer and w._halves.drawer.rolled end)
    add("drawer.pinned", function() return w._halves and w._halves.drawer and w._halves.drawer.pinned end)
    add("invDrawerOpen", function() return w._invDrawerOpen end)
    -- (Nov 18 2026, r7: the developer's three causes: the drawer not a tab drawer, a button held, the spot inside)
    add("_drawerOpen", function() return w._drawerOpen end)
    add("_drawerMode", function() return w._drawerMode end)
    add("mouseDown0", function() return isMouseButtonDown(0) end)
    add("mouseDown1", function() return isMouseButtonDown(1) end)
    add("absX", function() return w:getAbsoluteX() end)
    add("absY", function() return w:getAbsoluteY() end)
    add("width", function() return w:getWidth() end)
    add("shownH", function()
        if type(w.shownHeight) == "function" then return w:shownHeight() end
        return w:getHeight()
    end)
    add("spot", function() return S.hv and S.hv.spot and (S.hv.spot[1] .. "," .. S.hv.spot[2]) end)
    add("mouse", function() return getMouseX() .. "," .. getMouseY() end)
    add("split", function() return ZeD.Halves.split(w) end)
    add("hit(drawer)", function()
        local a, b = ZeD.Halves.hit(w, "drawer", getMouseX() - w:getAbsoluteX(), getMouseY() - w:getAbsoluteY(), ZeD.Halves.split(w))
        return tostring(a) .. "/" .. tostring(b)
    end)
    return table.concat(out, ", ")
end
function H.halvesBack()
    H.mouseBack()
    if not S.hv then return end
    local w = RT.cw()
    if w then
        pcall(ZeD.Halves.showAll, w)
        pcall(function() local ww = RT.ww(); if ww and ww._halves then ZeD.Halves.showAll(ww) end end)
        pcall(ZeD.Halves.setPin, w, "drawer", S.hv.pin)
    end
    S.hv = nil
    RT.charTab("loot")
end
-- queued transfers shown on rows (ZeD_InvTip.queued): two moves to the floor queued, both rows say waiting; the
-- queue stopped, neither does
Q.step(6, function()
    S.qFloor = nil
    local ww = RT.ww()
    for _, e in ipairs((ww and ww._containers) or {}) do if not S.qFloor and e.isFloor then S.qFloor = e.inventory end end
    if not S.qFloor then Q.skip("queued transfers on rows", "the World window lists no floor here"); return end
    H.stopActions()
    -- (Nov 18 2026, Build: a carried-to-floor move takes about 1 tick (the apple) or 2.5 (the book), so the moves had
    -- landed before the check, and on the Deck an earlier step had used one item up. Two fresh items, each move given
    -- an explicit time (maxTime 300) so both still wait at the check; taken back after.)
    S.qItems = {}
    for _, ft in ipairs({ "Base.Apple", "Base.Book" }) do
        local it = RT.give(ft)
        if it then
            S.qItems[#S.qItems + 1] = it
            pcall(function() ISTimedActionQueue.add(ISInventoryTransferAction:new(S.p, it, S.p:getInventory(), S.qFloor, 300)) end)
        end
    end
end)
Q.step(2, function()
    if not S.qFloor then return end
    local c, IT = H.content(), ZeD.InvTip
    local n = 0
    for _, it in ipairs(S.qItems) do if IT.queued(c, it) ~= nil then n = n + 1 end end
    Q.check(#S.qItems == 2 and n == 2, "queued transfers: both moves waiting show on their rows (InvTip.queued)", n .. " of " .. #S.qItems)
    H.stopActions()
end)
Q.step(3, function()
    if not S.qFloor then return end
    local c, IT = H.content(), ZeD.InvTip
    local n = 0
    for _, it in ipairs(S.qItems) do if IT.queued(c, it) ~= nil then n = n + 1 end end
    Q.check(n == 0, "queued transfers: the queue stopped, no row shows a move waiting", n .. " still shown")
    -- the two given for this check go back now (wherever they are: carried, or on the floor if one landed)
    for _, it in ipairs(S.qItems or {}) do
        pcall(function() local ic = it:getContainer(); if ic then ic:Remove(it) end end)
        pcall(function()
            local wi = it:getWorldItem()
            if wi and wi:getSquare() then wi:getSquare():transmitRemoveItemFromSquare(wi) end
        end)
    end
end)
-- the watch: the game's own clock and speed controls parked off the screen while ZeD's watch is on (ZeD_Watch)
Q.step(2, function()
    if ZeD.Safe and ZeD.Safe.on("watch") then Q.skip("the game's clock parked", "safe mode has the watch"); return end
    local c, sc = UIManager.getClock(), UIManager.getSpeedControls()
    local cy, sy = c and c:getY(), sc and sc:getY()
    Q.check(cy ~= nil and sy ~= nil and cy < 0 and sy < 0, "watch: the game's clock and speed controls are parked off screen",
        "clock y " .. tostring(cy) .. ", speed controls y " .. tostring(sy))
end)
-- the Maps tab's key (MapsTabKey): its header button opens the key over the map, on screen; its close box shuts it
function H.mapZone(pred)
    local w = RT.ww()
    for _, z in ipairs((w and w._mapExtZones) or {}) do if pred(z) then return z end end
    return nil
end
-- (Nov 18 2026: the header's buttons are zoned "map:ext:<id>" (MapsTabExt drawBtn), so the Key button is "map:ext:key")
function H.isKeyBtn(z) return z.id == "map:ext:key" end
function H.isKeyClose(z) return z.id == "map:key:close" end
Q.step(4, function()
    S.mapsTab = RT.worldTab("maps")
    S.keyWas = RT.ww() and RT.ww()._mapKeyOpen
end)
Q.waitFor(4, 300, function() return H.mapZone(H.isKeyBtn) ~= nil end, function(ok)
    S.keyArm = Q.check(S.mapsTab and ok, "Maps: the header has its Key button")
    if not S.keyArm then return end
    local z = H.mapZone(H.isKeyBtn)
    pcall(ZeD.MapsTabExt.onClick, RT.ww(), z.x + 1, z.y + 1)
end)
Q.waitFor(2, 120, function() return not S.keyArm or H.mapZone(H.isKeyClose) ~= nil end, function(ok)
    if not S.keyArm then return end
    Q.check(ok and RT.ww()._mapKeyOpen == true, "Maps: the Key button opens the map's key", tostring(RT.ww()._mapKeyOpen))
    RT.bounds(Q, "the map's key")
    local z = H.mapZone(H.isKeyClose)
    if z then pcall(ZeD.MapsTabExt.onClick, RT.ww(), z.x + 1, z.y + 1) end
end)
Q.step(4, function()
    if not S.keyArm then return end
    local w = RT.ww()
    Q.check(not w._mapKeyOpen, "Maps: the key's close box shuts it", tostring(w._mapKeyOpen))
    w._mapKeyOpen = S.keyWas
end)
-- Read Map on a paper map (the game's ISInventoryPaneContextMenu.onCheckMap, hooked): ZeD's map opens on the paper in
-- a pop-out; the paper taken from the main inventory, the pop-out folds. (The game's read marks the map read for the
-- character, as reading any map does: that stays.)
Q.step(4, function()
    RT.worldTab("loot")
    S.paper = nil
    for _, ft in ipairs({ "Base.MuldraughMap", "Base.WestpointMap", "Base.RosewoodMap", "Base.RiversideMap" }) do
        if not S.paper then S.paper = RT.give(ft) end
    end
    if not Q.check(S.paper ~= nil, "Read Map: a town map is given", "") then return end
    pcall(ISInventoryPaneContextMenu.onCheckMap, S.paper, S.pn)
end)
Q.waitFor(2, 300, function() local w = RT.ww(); return S.paper == nil or (w ~= nil and w._mapPaperItem == S.paper and w._mapPopout ~= nil) end, function(ok)
    if not S.paper then return end
    Q.check(ok, "Read Map on a paper map opens ZeD's map on that paper (a pop-out)", tostring(RT.ww() and RT.ww()._mapPaperItem))
    RT.bounds(Q, "the paper map")
    pcall(function() S.paper:getContainer():Remove(S.paper) end)
end)
Q.waitFor(2, 300, function() local w = RT.ww(); return S.paper == nil or w == nil or w._mapPopout == nil end, function(ok)
    if not S.paper then return end
    Q.check(ok, "Read Map: the paper gone from the main inventory, its map folds away")
    H.paperBack()
end)
function H.paperBack()
    local w = RT.ww()
    pcall(function() if w and w._mapPopout then ZeD.MapsTab.closePopout(w, true) end end)
    if not RT.ww() then pcall(ZeD_WorldWindow.open, S.pn) end
end
-- every wheel is drawn ZeD's way (Overrides/Wheels.lua): the game's own emote wheel opens as ZeD's (menu._zed), on
-- screen; refilled with the game's addSlice, a click towards a slice runs that slice's command
Q.step(4, function()
    S.wh = getPlayerRadialMenu(S.pn)
    S.whOk = pcall(function() ISEmoteRadialMenu:new(S.p):fillMenu() end)
end)
Q.waitFor(2, 120, function() return S.wh == nil or S.wh:isReallyVisible() end, function(ok)
    local m = S.wh
    if not Q.check(m ~= nil and ok and m._zed == true, "wheel: the game's emote wheel opens drawn ZeD's way (menu._zed)",
        "opened " .. tostring(S.whOk) .. ", zed " .. tostring(m and m._zed)) then pcall(function() m:undisplay() end); return end
    RT.bounds(Q, "the emote wheel")
    S.whHit = nil
    m:clear()
    for i = 1, 4 do m:addSlice("ZeD QA " .. i, nil, function(n) S.whHit = n end, i) end
    local _, _, r, cx, cy = ZeD.Wheel.geom(m)
    local a = math.rad(-90 + 90)   -- (slice 2 of 4: a quarter turn from the top)
    local x, y = cx + r * math.cos(a), cy + r * math.sin(a)
    local okP = pcall(m.onMouseDown, m, x, y)
    Q.check(okP and S.whHit == 2, "wheel: a click towards a slice runs that slice's command",
        "slice under the click " .. tostring(ZeD.Wheel.sliceFromMouse and ZeD.Wheel.sliceFromMouse(m, x, y)) .. ", ran " .. tostring(S.whHit))
    pcall(function() m:undisplay() end)
end)
-- the form card (ZeD_FormCard): opened from a spec it shows on screen; A on its check row runs the row; B is its
-- cancel, and the card closes
Q.step(4, function()
    S.fc, S.fcRun, S.fcCancel, S.fcDone = nil, 0, 0, 0
    local FC = ZeD.FormCard
    if not (FC and FC.open) then Q.check(false, "the form card is loaded"); return end
    pcall(function()
        S.fc = FC.open({ title = "ZeD QA", playerNum = S.pn,
            rows = function() return { { k = "label", text = "ZeD QA" },
                { k = "check", id = "qa", text = "ZeD QA check", on = S.fcRun > 0, run = function() S.fcRun = S.fcRun + 1 end } } end,
            band = function() return { buttons = { { id = "ok", text = getText("UI_Ok"), run = function(card) card:finish() end } } } end,
            cancel = function(card) S.fcCancel = S.fcCancel + 1; card:finish() end,
            onFinish = function() S.fcDone = S.fcDone + 1 end })
    end)
end)
Q.waitFor(2, 120, function() return S.fc == nil or S.fc:isReallyVisible() end, function(ok)
    local fc = S.fc
    if not Q.check(fc ~= nil and ok, "form card: it opens from its spec and shows") then return end
    RT.bounds(Q, "the form card")
    -- (Nov 18 2026: the card answers A only with a pad (its focused() needs joyfocus); a jd of nil left it none, and
    -- update() takes joyfocus from the pad or FC.qaJoy each frame. A stand-in pad is passed, and held in qaJoy.)
    local jd = { player = S.pn, id = S.pn }
    ZeD.FormCard.qaJoy = jd
    fc.joyfocus = jd
    fc._focus = 1
    pcall(fc.onJoypadDown, fc, Joypad.AButton, jd)
    Q.check(S.fcRun == 1, "form card: A on its check row runs the row", S.fcRun .. " runs")
    pcall(fc.onJoypadDown, fc, Joypad.BButton, jd)
    ZeD.FormCard.qaJoy = nil
    Q.check(S.fcCancel == 1 and S.fcDone == 1 and not fc:isVisible(), "form card: B is its cancel and the card closes",
        "cancel " .. S.fcCancel .. ", finished " .. S.fcDone)
end)
function H.ledgerBack()
    pcall(H.stoveBack)
    H.halvesBack()
    H.paperBack()
    pcall(function() ZeD.FormCard.qaJoy = nil end)
    pcall(function() if S.fc and not S.fc._done then S.fc:finish() end end)
    pcall(function() if S.wh and S.wh:isReallyVisible() then S.wh:undisplay() end end)
    pcall(function() local w = RT.ww(); if w and S.keyArm then w._mapKeyOpen = S.keyWas end end)
    pcall(function() local w = RT.cw(); if w and S.tso ~= nil then w._tabScrollOffset = S.tso end end)
    pcall(function() if S.gen then S.gen:setActivated(false); S.gen:setConnected(false) end end)
end

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    pcall(H.rkCmpBack)   -- (the rack Stop diagnostics: nothing left wrapped, safe mode as found)
    H.ledgerBack()
    H.stopActions()
    H.padOff()
    H.closeCard()
    -- (what the card checks change, as found: a run cut short leaves them)
    pcall(function() local m = H.ctxMenu(); if m then m:close() end end)
    pcall(function() local t = H.textPrompt(); if t then H.promptAnswer(t, false) end end)
    pcall(function() local LU = ZeD.ListsUI; local m = LU and LU.popup; if m and m._ctx and m._ctx.open then m:close() end end)   -- (no ListsUI: ZeD alone after the split)
    pcall(function() local LT = H.loadOpt(); local o = LT and LT.loadoutsOption; if S.loadWas and o then o:setValue(S.loadWas) end end)
    pcall(function() if S.batName and S.bat:getName() ~= S.batName then S.bat:setName(S.batName); S.bat:setCustomName(false) end end)
    pcall(function() local w = RT.cw(); if w then w._equipSelected = nil end end)
    pcall(function() local st = H.craftState(); if st and st.selected then ZeD.CraftingCore.closeCraft(st) end end)
    if S.charTabWas and S.charTabWas ~= "equip" then RT.charTab(S.charTabWas) end
    H.closeGameStationWindows()
    pcall(function() if S.stove and ZeD.TwoWayFull.showingObj(S.pn, S.stove) then ZeD.TwoWayFull.close(S.pn) end end)
    pcall(S.ST.unbind, S.p)
    -- the list: the stacks and the scroll as they were, nothing selected
    local c = H.content()
    if c then
        for k, v in pairs(S.stackWas) do c._expandedStacks[k] = (v ~= false) and v or nil end
        if S.scrollWas and c._scroll then pcall(function() c._scroll:setScrollPos(S.scrollWas) end) end
        c._selectedItems = {}
        c._lastClickedItem = nil
    end
    -- the dropped pencil off the floor (its world item), the rest by the kit's take-back
    for _, k in ipairs({ "apple", "bat", "book", "pencil" }) do
        local it = S[k]
        if it then
            pcall(function()
                local wi = it:getWorldItem()
                if wi then
                    local sq = wi:getSquare()
                    if sq then sq:transmitRemoveItemFromSquare(wi) end
                    pcall(function() wi:removeFromWorld() end)
                    pcall(function() wi:removeFromSquare() end)
                    it:setWorldItem(nil)
                end
            end)
        end
    end
    -- what was placed and built, the campfire
    for _, o in ipairs(S.placed) do H.removeObj(o) end
    for _, o in ipairs(S.built) do H.removeObj(o) end
    for _, sq in ipairs(S.fires) do
        pcall(function()
            local lo = SCampfireSystem.instance:getLuaObjectOnSquare(sq)
            if lo then SCampfireSystem.instance:removeCampfire(lo) end
        end)
    end
    S.placed, S.built, S.fires = {}, {}, {}
    pcall(function() RT.ww()._containersDirty = true end)
end)
Q.step(5, function()
    RT.takeBack()
    -- the hands as they were
    pcall(function()
        if S.handWas then
            S.p:setPrimaryHandItem(S.handWas[1])
            S.p:setSecondaryHandItem(S.handWas[2])
        end
    end)
    RT.worldTab("loot")
    if S.pairWas == false then RT.pairShut() end
    local left = 0
    for _, k in ipairs({ "apple", "bat", "book", "pencil" }) do
        if S[k] and S.p:getInventory():containsRecursive(S[k]) then left = left + 1 end
    end
    Q.check(left == 0, "put back: the things given are taken back", left .. " left")
end)
Q.waitFor(5, 600, function() return S.fireSq == nil or H.campLua(S.fireSq) == nil end, function(ok)
    if S.fireSq then Q.check(ok, "put back: the campfire is gone") end
    local left = 0
    for _, o in ipairs({ S.gen, S.washer, S.fridge, S.stove, S.kiln }) do
        local idx = -1
        pcall(function() idx = o:getObjectIndex() end)
        if idx >= 0 then left = left + 1 end
    end
    Q.check(left == 0, "put back: everything placed or built is taken away", left .. " left")
end)
Q.start()
