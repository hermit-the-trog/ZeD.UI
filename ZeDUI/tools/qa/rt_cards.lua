-- ZeDUI/tools/qa/rt_cards.lua  (Nov 18 2026, QA): the release test's item cards, object cards and stations
-- (ZeDUI/qa/RELEASE_TEST.md, the row "rt_cards.lua"). Built on rt_kit.lua (run it first); grep "ZEDQA rt_cards".
--
-- ITEM CARDS (ItemCard.lua, ItemCardOrganism.lua, ItemFactsPanel.lua, ItemActionHooks.lua). An apple, a baseball bat,
-- a book and a pencil are given to the main inventory (their stacks opened so each has its own row).
--   mouse   a click on the bat's row (the list's own onMouseDown / onMouseUp) opens its card in the drawer; the card is
--           220, 260 or 480 wide; its top facts show the bat's weight ("n.n kg") and its facts panel its condition
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
S.RING1 = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
S.RING2 = { { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 }, { 2, 2 }, { -2, -2 }, { 2, -2 }, { -2, 2 }, { 3, 0 }, { -3, 0 } }
S.BUILD = { { 4, -4 }, { -4, -4 }, { 4, 4 }, { -4, 4 }, { 5, 0 }, { -5, 0 }, { 0, -5 }, { 0, 5 } }

-- ===================================================================== helpers
function H.px(n) return ZeD.T.px(n) end
function H.cardW(w)
    for _, n in ipairs({ 220, 260, 480 }) do if math.abs((w or 0) - H.px(n)) <= 1 then return true end end
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
-- (a condition, every frame: the row drawn last frame, else the list one step further down; wraps at the end)
function H.seekRow(item)
    local c = H.content()
    if not c then return false end
    if H.rowZone(item) then return true end
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
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
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
function H.queueA(holdMs)
    Q.step(1, function()
        if S.armA == false then return end
        RT.pad("A", true); RT.padDown(Joypad.AButton, RT.cw())
    end)
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
function H.freeSq(offsets)
    for _, o in ipairs(offsets) do
        local k = o[1] .. "," .. o[2]
        local sq = H.sq(o[1], o[2])
        local free = false
        if sq and not S.used[k] then
            pcall(function() free = sq:isFree(false) and not sq:HasTree() and sq:getVehicleContainer() == nil end)
        end
        if free then S.used[k] = true; return sq end
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
function H.build(full)
    local info = H.findInfo(full)
    if not info then return nil, "no entity info for " .. full end
    local px, py, pz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for _, o in ipairs(S.BUILD) do
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
            if #new > 0 then return new end
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

-- Eat: A held on the card's Eat (the game's ISEatFoodAction)
Q.step(10, function() end)
H.queueVerb("EAT", "eat", 600)
Q.waitFor(2, 120, function() return H.queueHead() == "ISEatFoodAction" end, function(ok)
    Q.check(ok, "eat: A held on Eat queues the game's own eat (ISEatFoodAction)", H.queueHead())
    H.stopActions()
end)

-- ===================================================================== item card: the mouse
Q.step(10, function() end)
H.queueClick("bat", "mouse")
Q.waitFor(2, 120, function() return H.cardOn(S.bat) and H.cardW(H.card():getWidth()) end, function(ok)
    local c = H.card()
    Q.check(H.cardOn(S.bat), "mouse: a click on the bat's row opens its card", H.nm(c and c.item))
    Q.check(c and H.cardW(c:getWidth()), "mouse: the card is half (220 / 260) or full (480) wide", c and math.floor(c:getWidth()))
end)
Q.step(15, function()
    local c = H.card()
    local m = c and c._model
    local wt = 0
    pcall(function() wt = S.bat:getActualWeight() end)
    local want = string.format("%.1f kg", wt)
    local r = m and H.row(m.stats, ZeD.tr("UI_ZeD_Weight"))
    Q.check(r ~= nil and r.value == want, "facts: the card shows the bat's weight", tostring(r and r.value) .. " (want " .. want .. ")")
    local cond, cmax = 0, 0
    pcall(function() cond, cmax = S.bat:getCondition(), S.bat:getConditionMax() end)
    local wantC = string.format("%d / %d", cond, cmax)
    local fr = m and H.factRow(m.facts, getText("Tooltip_weapon_Condition"))
    Q.check(fr ~= nil and fr.value == wantC, "facts: the card's facts show the bat's condition", tostring(fr and fr.value) .. " (want " .. wantC .. ")")
    RT.bounds(Q, "the bat's item card")
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

-- Drop: the pencil's card, Drop (the game's drop: it leaves the inventory)
Q.waitMs(600)
H.queueClick("pencil", "drop")
Q.waitFor(2, 120, function() return H.cardOn(S.pencil) end, function(ok)
    Q.check(ok, "drop: a click on the pencil's row opens its card", H.nm(H.card() and H.card().item))
end)
Q.step(10, function() end)
-- (Nov 18 2026, Build: by design an item not worn or held shows its primary verb and MORE; MORE opens the item's
-- whole context menu at the button, and Drop is there, the game's ContextMenu_Drop. So: MORE, then that row.)
function H.ctxMenu()
    local m = nil
    pcall(function() local v = getPlayerContextMenu(S.pn); m = v and v._zedMenu end)
    return m
end
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
Q.step(5, function() H.padOff() end)

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
    if S.gen then S.placed[#S.placed + 1] = S.gen end
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

-- the campfire: the game's Info
Q.step(10, function()
    local sq = H.freeSq(S.RING2)
    if not sq then Q.check(false, "fire: a free square beside the character", "none"); return end
    local ok = pcall(function() SCampfireSystem.instance:addCampfire(sq) end)
    S.fires[#S.fires + 1] = sq
    S.fireSq = sq
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
    if S.washer then S.placed[#S.placed + 1] = S.washer end
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
    local sq = H.freeSq(S.RING2)
    if not sq then Q.check(false, "stove: a free square beside the character", "none"); return end
    local ok = pcall(function()
        S.stove = IsoStove.new(getCell(), sq, getSprite("appliances_cooking_01_12"))
        pcall(function() S.stove:createContainersFromSpriteProperties() end)
        sq:AddSpecialObject(S.stove)
        if S.stove:getObjectIndex() < 0 then sq:AddTileObject(S.stove) end
    end)
    if S.stove then S.placed[#S.placed + 1] = S.stove end
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

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    H.stopActions()
    H.padOff()
    H.closeCard()
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
