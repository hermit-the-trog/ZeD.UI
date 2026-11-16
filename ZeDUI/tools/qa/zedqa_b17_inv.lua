-- ZeDUI/tools/qa/zedqa_b17_inv.lua  (Nov 16 2026, QA): beta 17's controller fixes in the running game, single player.
-- The pad is driven as zedqa_pad_marks.lua's header says: Focus.dispatchJoypadDown for every press, Focus.qaButton
-- (name, false) after an A or X so the tick resolves a tap, handed back (nil) on the next step.
--   249  a trash can placed beside the character with three junk things in it: A on its Remove all asks, and the
--        question opens with the pad on Cancel; B closes it, the pad back on Remove all; asked again, A on Cancel
--        closes it the same way. The three things are still there each time. (No other container button asks.)
--   252  A on each text box opens the pad keyboard on that box, and closing it (B) leaves the pad on the box: the
--        Journal's write box and its search, the Notebooks quick note, the Recipes search (Character window), the
--        Craft and Build searches (World window).
--   254  the Journal's Into picker is a stop (a notebook and a pencil given for the run): A steps it to the
--        notebook and back.
--   253  an animal zone made for the run ("ZEDQA b17 pen"): X on its overview card and on its name opens the zone's
--        menu; Remove lands on Cancel and B cancels (the zone stays); Rename lands on Save and B cancels (the name
--        stays). Nothing is renamed or removed but the run's own zone, taken away at the end.
--   255  L3 twice on the Character window's list: Name A-Z, then Name Z-A, then Category.
--   256  A on a category heading folds it and A again opens it: the Character window's list, its Grid view, a
--        World window Loot column (the trash can), and with every category folded (list and grid).
-- Pictures: Screenshots/zqa_b17i_trash_ask_cancel.png, zqa_b17i_journal_keyboard.png, zqa_b17i_cat_folded.png.
-- Puts back: keyboard, menus and question shut, the sort, folds and Grid choice as found, the column shut, the
-- trash can, its things and the given things gone, the zone gone, tabs and the Journal page back, speed and god
-- mode as found, the pad handed back, the windows as found. grep "ZEDQA b17i".
local p = getPlayer()
local pn = p:getPlayerNum()
local Focus, Det = ZeD.Input.Focus, ZeD.Input.Detector
local IR, CT, KB, AT, JT = ZeD.InventoryRenderer, ZeD.ContainerControls, ZeD.Keyboard, ZeD.AnimalsTab, ZeD.JournalTab
local function say(s) print("ZEDQA b17i " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b17i_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
if not (Focus and Focus.qaButton and CT and KB and KB.edit and IR and IR.catElements and AT and AT.zoneStops and JT) then
    say("ERR beta 17's pieces are not loaded (Focus.qaButton, KB.edit, IR.catElements, AT.zoneStops)"); say("DONE"); return
end
local S = { held = {}, given = {}, ZONE = "ZEDQA b17 pen" }
local function cw() return ZeD_CharacterWindow.getWindow(pn) end
local function ww() return ZeD_WorldWindow.getWindow(pn) end

-- ---- stops and presses
local function fresh(w) if w and w._focusFresh then pcall(w._focusFresh, w) end end
local function stops(w, pred)
    fresh(w)
    local out = {}
    for _, z in ipairs(w and w._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do if pred(e, z) then out[#out + 1] = { e = e, z = z } end end
    end
    return out
end
-- the pad onto the first stop pred finds (any zone of w); the stop, or nil
local function focusOn(w, pred)
    local hit = stops(w, pred)[1]
    if not hit then return nil end
    local e, z, id = hit.e, hit.z, hit.e.id
    Focus.claimFocus(w)
    if Focus.focusWhere(w, z.zone, function(x) if id ~= nil then return x.id == id end; return x == e end) then return e, z end
    for zi, zz in ipairs(w._focusRing) do   -- (a zone not focusable this frame: seated by hand)
        if zz == z then w._focusIdx = zi; for ei, x in ipairs(z.elements) do if x == e then z.focusedElementIdx = ei end end end
    end
    return e, z
end
local function byId(id) return function(e) return e.id == id end end
local function curId(w) local e = w and Focus.getFocusedElement(w); return e and e.id end
local function tap(w, btn, name)
    Focus.dispatchJoypadDown(w, btn)
    if name then Focus.qaButton(name, false, pn); S.held[#S.held + 1] = name end
end
local function letGo() for _, n in ipairs(S.held) do Focus.qaButton(n, nil, pn) end; S.held = {} end
local function A(w) tap(w, Joypad.AButton, "A") end
local function X(w) tap(w, Joypad.XButton, "X") end
local function B(w) tap(w, Joypad.BButton) end

-- ---- the pad keyboard
local function kbUp()
    local ok, v = pcall(function() return KB.isVisible() or (OnScreenKeyboard and OnScreenKeyboard.IsVisible and OnScreenKeyboard.IsVisible()) end)
    return ok and v and true or false
end
local function kbBox() local k = KB.instance; return k and k.textEntryBox end
local function kbClose()   -- (the keyboard's own B: it keeps the text and puts itself away)
    local k = KB.instance
    if KB.isVisible() then local ok, e = pcall(k.onJoypadDown, k, Joypad.BButton, k.joypadData); if not ok then say("ERR keyboard B: " .. tostring(e)) end
    elseif kbUp() then pcall(function() OnScreenKeyboard.Hide() end) end
end

-- ---- the menu a press opens (the zone's menu): the opened one is caught, the open put back at the end
local openWas = ZeD_ContextList and ZeD_ContextList.open
if openWas then ZeD_ContextList.open = function(self, ...) S.menu = self; return openWas(self, ...) end end
local function menuShut() if S.menu and S.menu._ctx and S.menu._ctx.open then pcall(function() S.menu:close() end) end end

-- ===================================================================== setup
step(5, function()
    if ZEDQA_LAYOUT_SNAP then S.snap = ZEDQA_LAYOUT_SNAP() end
    if not ZeD_CharacterWindow.isOpen(pn) then ZeD_CharacterWindow.toggleBothPaired(pn); S.opened = true end
    Det.setLockedMode(Det.MODE_GAMEPAD)
    S.godWas = p:isGodMod(); p:setGodMod(true)
    S.speedWas = getGameSpeed()
    if S.speedWas == 0 then setGameSpeed(1) end   -- (a container button does nothing while paused: CT.press)
    -- things for the Journal (a notebook to write in, a pencil to write with) and the list's categories
    for _, t in ipairs({ "Base.Notebook", "Base.Pencil", "Base.Apple", "Base.Eraser" }) do
        local it = p:getInventory():AddItem(t)
        if it then S.given[#S.given + 1] = it end
    end
    -- a trash can beside the character (a trashcontainers_01 sprite the game marks IsTrashCan)
    S.sq = getCell():getGridSquare(math.floor(p:getX()) + 1, math.floor(p:getY()), math.floor(p:getZ()))
    for n = 0, 23 do
        local name = "trashcontainers_01_" .. n
        local spr = S.sq and getSprite(name)
        local props = spr and spr:getProperties()
        if props and props:has("IsTrashCan") then
            local o = IsoObject.new(S.sq, name, nil, false)
            S.sq:AddTileObject(o)
            pcall(function() o:createContainersFromSpriteProperties() end)
            local inv = o:getContainer()
            if inv then
                pcall(function() inv:setExplored(true) end)
                S.trash, S.trashInv = o, inv
                for _, t in ipairs({ "Base.Eraser", "Base.Tweezers", "Base.Corkscrew" }) do inv:AddItem(t) end
                break
            end
            pcall(function() S.sq:transmitRemoveItemFromSquare(o) end); pcall(function() S.sq:RemoveTileObject(o) end)
        end
    end
    say("setup: trash can " .. tostring(S.trashInv ~= nil) .. ", " .. #S.given .. " things given, paused was " .. tostring(S.speedWas == 0))
end)
step(75, function()   -- (the World window looks for containers every 30 frames)
    local w, c = ww(), cw()
    S.cTab, S.wTab, S.pageWas = c._activeTab, w._activeTab, c._journalSubTab
    local on = w._containers and w._containers[w._activeContainer or 1]
    S.onShow = on and on.inventory
    ZeD_WorldWindow.openTab(pn, "loot")
    local st = S.trashInv and stops(w, function(e, z) return z.zone == "worldContainerStrip" and e.inventory == S.trashInv end)[1]
    if st and st.e.onActivate then st.e.onActivate(w, st.e) end
    check(st ~= nil, "249: the trash can has a stop on the World window's container strip")
end)

-- ===================================================================== 249 the trash question
local function trashCount() return S.trashInv and S.trashInv:getItems():size() or -1 end
local function specOf(e)
    local cc = ww()._mainContent and ww()._mainContent._cc
    local h = e and e.ccIdx and cc and cc.hits and cc.hits[e.ccIdx]
    return h and h.spec and h.spec.id
end
local function onRemoveAll(e, z) return z.zone == "worldCtl" and specOf(e) == "trash" end
local function askUp() local cc = ww()._mainContent._cc; return cc and cc.ask ~= nil end
step(30, function()
    if not S.trashInv then say("not run: 249 (no trash can could be placed)"); return end
    S.t249 = focusOn(ww(), onRemoveAll) ~= nil
    if not check(S.t249, "249: Remove all is a stop in the trash can's buttons") then return end
    A(ww())
end)
step(20, function()
    if not S.t249 then return end
    local e = Focus.getFocusedElement(ww())
    check(askUp(), "249: A on Remove all asks first")
    check(e and e.ccKey == "no", "249: the question opens with the pad on Cancel (" .. tostring(e and e.ccKey) .. ")")
    shot("trash_ask_cancel")
    B(ww())
end)
step(20, function()
    if not S.t249 then return end
    check(not askUp(), "249: B closes the question")
    check(specOf(Focus.getFocusedElement(ww())) == "trash", "249: after B the pad is back on Remove all")
    check(trashCount() == 3, "249: nothing deleted after B (" .. trashCount() .. " of 3)")
    A(ww())
end)
step(20, function()
    if not S.t249 then return end
    local e = Focus.getFocusedElement(ww())
    if askUp() and e and e.ccKey == "no" then A(ww())   -- (A only ever on Cancel)
    else check(false, "249: asked again, the pad is on Cancel (" .. tostring(e and e.ccKey) .. ")"); B(ww()) end
end)
step(20, function()
    if not S.t249 then return end
    check(not askUp(), "249: A on Cancel closes the question")
    check(specOf(Focus.getFocusedElement(ww())) == "trash", "249: after Cancel the pad is back on Remove all")
    check(trashCount() == 3, "249: nothing deleted after Cancel (" .. trashCount() .. " of 3)")
    say("not run: 249 another container question (Remove all is the only container button that asks, ContainerControls.lua)")
end)

-- ===================================================================== 252 / 254 text boxes
-- prep runs, then A on the stop; the keyboard checked on the box (entry: the box it should be on, nil: not read),
-- closed with its B, then the pad checked on the stop. must: a missing stop fails (else "not run").
local function boxCheck(tag, getW, id, prep, entry, must, pic)
    step(30, function() if prep then prep() end end)
    step(20, function()
        S.box = nil
        local w = getW()
        if not focusOn(w, byId(id)) then
            if must then check(false, tag .. ": the box is a controller stop (" .. id .. ")")
            else say("not run: " .. tag .. " (no stop " .. id .. " on screen)") end
            return
        end
        S.box = w
        A(w)
    end)
    step(15, function()
        if not S.box then return end
        check(kbUp(), tag .. ": A opens the pad keyboard")
        local want = entry and entry()
        if want then check(kbBox() == KB.entryOf(want), tag .. ": the keyboard types into this box") end
        if pic then shot(pic) end
        kbClose()
    end)
    step(10, function()
        if not S.box then return end
        check(not kbUp(), tag .. ": B puts the keyboard away")
        check(Focus.getFocusedWindow(pn) == S.box and curId(S.box) == id,
            tag .. ": the pad is back on the box (" .. tostring(curId(S.box)) .. ")")
    end)
end
local function page(n) return function() ZeD_CharacterWindow.openTab(pn, "journal"); JT.setPage(cw(), n) end end
boxCheck("252 Journal write box", cw, "journal:__write", page(1), function() return cw()._journalInput end, true, "journal_keyboard")
boxCheck("252 Journal search", cw, "journal:__find", page(1), function() return cw()._journalFindZone and cw()._journalFindZone.field end, true)
boxCheck("252 Notebooks search", cw, "journal:__find", page(2), function() return cw()._journalFindZone and cw()._journalFindZone.field end, false)
boxCheck("252 Notebooks quick note", cw, "jr:note", page(2), nil, false)
boxCheck("252 Recipes search", cw, "jrecipe:search", page(4), function() return cw()._jrecipeState and cw()._jrecipeState._searchField end, true)
boxCheck("252 Craft search", ww, "craft:search", function() ZeD_WorldWindow.openTab(pn, "craft") end,
    function() return ww()._craftState and ww()._craftState._searchField end, true)
boxCheck("252 Build search", ww, "build:search", function() ZeD_WorldWindow.openTab(pn, "build") end,
    function() return ww()._buildState and ww()._buildState._searchField end, true)

-- 254: Into (the notebook carried): A steps the log only -> the notebook -> the log only; its width follows its label
local function intoW() local z = cw()._journalIntoZone; return z and z.w end
step(30, page(1))
step(20, function()
    S.into = focusOn(cw(), byId("jr:into")) ~= nil
    if not check(S.into, "254: Into is a controller stop on the Journal page (a notebook carried)") then return end
    S.intoW0 = intoW()
    A(cw())
end)
step(20, function()
    if not S.into then return end
    S.intoW1 = intoW()
    check(curId(cw()) == "jr:into", "254: the pad stays on Into after A")
    check(S.intoW1 ~= S.intoW0, "254: A steps Into to the notebook (width " .. tostring(S.intoW0) .. " -> " .. tostring(S.intoW1) .. ")")
    A(cw())
end)
step(20, function()
    if not S.into then return end
    check(intoW() == S.intoW0, "254: A again steps back to the log only (width " .. tostring(intoW()) .. ")")
end)

-- ===================================================================== 253 animal zones
local function zoneObj() local z; pcall(function() z = DesignationZoneAnimal.getZoneByName(S.ZONE) end); return z end
local function aState() return AT.getState(ww()) end
step(10, function()
    if not (DesignationZoneAnimal and DesignationZoneAnimal.new) then say("not run: 253 (no DesignationZoneAnimal)"); return end
    S.zoneMine = zoneObj() ~= nil   -- (left by an earlier run of this script: its name says it is ours)
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    -- (zedqa_animals.lua's way: DesignationZoneAnimal.new on a 5x5 spot no zone covers)
    for _, o in ipairs(S.zoneMine and {} or { { 3, 3 }, { -8, 3 }, { 3, -8 }, { -8, -8 } }) do
        local clear = true
        for dy = 0, 4 do for dx = 0, 4 do
            local okZ, zz = pcall(DesignationZoneAnimal.getZone, px + o[1] + dx, py + o[2] + dy, pz)
            if okZ and zz then clear = false end
        end end
        if clear then
            local ok, e = pcall(DesignationZoneAnimal.new, S.ZONE, px + o[1], py + o[2], pz, px + o[1] + 4, py + o[2] + 4, true)
            if not ok then say("ERR zone: " .. tostring(e)) end
            break
        end
    end
    S.zoneMine = zoneObj() ~= nil
    if not S.zoneMine then say("not run: 253 (no clear 5x5 spot for a zone near the character)"); return end
    local st = aState()
    S.aWas = { view = st.view, zoneName = st.zoneName, animalRef = st.animalRef, prevView = st.prevView }
    ZeD_WorldWindow.openTab(pn, "animals")
    st.view = "overview"
end)
step(40, function()
    if not S.zoneMine then return end
    S.menu = nil
    if focusOn(ww(), byId("animals:zonecard:" .. S.ZONE)) then X(ww())
    else say("not run: 253 X on the zone's card (its card is not on screen in the overview)") end
end)
step(20, function()
    if not S.zoneMine then return end
    if S.menu then check(S.menu._ctx.open and S.menu.headText == S.ZONE, "253: X on the zone's card opens the zone's menu (" .. tostring(S.menu.headText) .. ")") end
    menuShut()
    AT.navigate(ww(), "zone", S.ZONE, nil)
end)
step(40, function()
    if not S.zoneMine then return end
    check(aState().view == "zone" and aState().zoneName == S.ZONE, "253: the zone's page is open")
    S.z253 = focusOn(ww(), byId("animals:zone:remove")) ~= nil
    if check(S.z253, "253: Remove zone is a controller stop") then A(ww()) end
end)
step(25, function()
    if not S.z253 then return end
    check(ww()._animalsRemoveConfirm == true, "253: A on Remove zone asks first")
    check(curId(ww()) == "animals:zone:no", "253: the remove question lands on Cancel (" .. tostring(curId(ww())) .. ")")
    B(ww())   -- (B on either answer is Cancel)
end)
step(25, function()
    if not S.z253 then return end
    check(not ww()._animalsRemoveConfirm, "253: B cancels the remove")
    check(zoneObj() ~= nil, "253: the zone is still there")
    check(curId(ww()) == "animals:zone:remove", "253: the pad is back on Remove zone (" .. tostring(curId(ww())) .. ")")
    S.z253r = focusOn(ww(), byId("animals:zone:rename")) ~= nil
    if check(S.z253r, "253: Rename is a controller stop") then A(ww()) end
end)
step(25, function()
    if not S.z253r then return end
    check(ww()._animalsRenaming == true, "253: A on Rename starts the rename")
    check(curId(ww()) == "animals:zone:save", "253: the rename lands on Save (" .. tostring(curId(ww())) .. ")")
    say("253 rename: the pad keyboard up " .. tostring(kbUp()) .. " (it opens only with a controller connected)")
    kbClose()
end)
step(15, function()
    if not S.z253r then return end
    local id = curId(ww()) or ""
    if not id:find("^animals:zone:") then focusOn(ww(), byId("animals:zone:save")) end
    B(ww())   -- (B on the rename's stops is its Cancel)
end)
step(25, function()
    if not S.z253r then return end
    check(not ww()._animalsRenaming, "253: B cancels the rename")
    check(zoneObj() ~= nil, "253: the zone keeps its name")
    check(curId(ww()) == "animals:zone:rename", "253: the pad is back on Rename (" .. tostring(curId(ww())) .. ")")
    S.menu = nil
    S.nameX = check(focusOn(ww(), byId("animals:zone:name")) ~= nil, "253: the zone's name is a controller stop")
    if S.nameX then X(ww()) end
end)
step(20, function()
    if not S.nameX then return end
    check(S.menu and S.menu._ctx.open and S.menu.headText == S.ZONE, "253: X on the zone's name opens the zone's menu")
    menuShut()
end)

-- ===================================================================== 255 L3 reverses the sort
local function cMain() return cw()._mainContent end
-- t emptied, then given src's entries (keys gathered first: nothing is cleared while pairs walks t)
local function refill(t, src)
    local ks = {}
    for k in pairs(t) do ks[#ks + 1] = k end
    for _, k in ipairs(ks) do t[k] = nil end
    for k, v in pairs(src) do t[k] = v end
end
step(30, function()
    if S.cTab then ZeD_CharacterWindow.openTab(pn, S.cTab) end
    local c = cMain()
    S.sortWas, S.foldsWas = { c._sortCol, c._sortAsc }, {}
    refill(S.foldsWas, c._collapsedGroups or {})
    c._sortCol, c._sortAsc = "name", true
end)
step(20, function()
    S.l3 = focusOn(cw(), function(e, z) return z.zone == "charMainInv" and e.item ~= nil end) ~= nil
    if check(S.l3, "255: the pad is on a row of the Character window's list") then tap(cw(), Joypad.LStickButton) end
end)
step(10, function()
    if not S.l3 then return end
    check(cMain()._sortCol == "name" and cMain()._sortAsc == false, "255: L3 on Name A-Z reverses it (" .. tostring(cMain()._sortCol) .. " " .. tostring(cMain()._sortAsc) .. ")")
    tap(cw(), Joypad.LStickButton)
end)
step(10, function()
    if not S.l3 then return end
    check(cMain()._sortCol == "cat" and cMain()._sortAsc == true, "255: L3 again goes on to Category A-Z (" .. tostring(cMain()._sortCol) .. " " .. tostring(cMain()._sortAsc) .. ")")
    cMain()._sortCol, cMain()._sortAsc = "cat", true   -- (headings only show sorted by category)
end)

-- ===================================================================== 256 category headings
-- one heading: A folds it, A again opens it (getW, zone name, the folds table the heading toggles)
local function foldCheck(tag, getW, zn, folds)
    step(30, function()
        S.fc = nil
        if not zn() then return end   -- (no such list this run: said where it was set up)
        local e = focusOn(getW(), function(x, z) return z.zone == zn() and x.isCatHead end)
        if not check(e ~= nil, tag .. ": a category heading is a controller stop") then return end
        S.fc = { id = e.id, cat = e.cat }
        A(getW())
    end)
    step(20, function()
        if not S.fc then return end
        check(folds() and folds()[S.fc.cat] == true, tag .. ": A folds " .. tostring(S.fc.cat))
        check(curId(getW()) == S.fc.id, tag .. ": the pad stays on the heading (" .. tostring(curId(getW())) .. ")")
        focusOn(getW(), byId(S.fc.id))
        A(getW())
    end)
    step(20, function()
        if not S.fc then return end
        check(folds() and folds()[S.fc.cat] == nil, tag .. ": A again opens " .. tostring(S.fc.cat))
    end)
end
-- every category folded: each heading still a stop, A on one opens it
local function allFolded(tag, pic)
    step(5, function()
        local c = cMain()
        for _, cat in ipairs(c._catOrder or {}) do c._collapsedGroups[cat] = true end
    end)
    step(30, function()
        S.fc = nil
        local c = cMain()
        local n = #stops(cw(), function(x, z) return z.zone == "charMainInv" and x.isCatHead end)
        check(n > 0 and n == #(c._catOrder or {}), tag .. ": every category folded, each heading is still a stop (" .. n .. " of " .. #(c._catOrder or {}) .. ")")
        if pic then shot(pic) end
        local e = focusOn(cw(), function(x, z) return z.zone == "charMainInv" and x.isCatHead end)
        if e then S.fc = { cat = e.cat }; A(cw()) end
    end)
    step(20, function()
        if S.fc then check(cMain()._collapsedGroups[S.fc.cat] == nil, tag .. ": all folded, A opens " .. tostring(S.fc.cat)) end
        refill(cMain()._collapsedGroups, {})
    end)
end
local function mainZone() return "charMainInv" end
local function mainFolds() return cMain()._collapsedGroups end
foldCheck("256 list", cw, mainZone, mainFolds)
allFolded("256 list", "cat_folded")
-- the Grid view (this container's own choice, its raw value kept to put back as found)
step(5, function()
    S.gkey = IR.containerKey(p:getInventory(), p)
    local store = p:getModData().ZeD_GridViews
    S.graw = store and S.gkey and store[S.gkey]
    if S.gkey then IR.setGridKey(S.gkey, true, p) end
end)
foldCheck("256 grid", cw, mainZone, mainFolds)
allFolded("256 grid")
step(10, function()
    local store = p:getModData().ZeD_GridViews
    if store and S.gkey then store[S.gkey] = S.graw end
end)
-- a World window Loot column: the ground on show, the trash can as a column beside it, sorted by category
local function colZone() return S.cs and ("worldMC" .. tostring(S.slot)) or nil end
local function colFolds() return S.cs and S.cs.collapsedGroups end
step(10, function()
    if not S.trashInv then return end
    local w = ww()
    ZeD_WorldWindow.openTab(pn, "loot")
    local fl = stops(w, function(e, z)
        local c = z.zone == "worldContainerStrip" and e.containerIdx and w._containers[e.containerIdx]
        return c and c.isFloor end)[1]
    if fl and fl.e.onActivate then fl.e.onActivate(w, fl.e) end
end)
step(30, function()
    if not S.trashInv then return end
    say("256 column: trash can as a column " .. tostring(ZeD_WorldWindow.toggleColumn(S.trashInv, pn)))
end)
step(40, function()
    local w = ww()
    for k, ci in ipairs(w._mcSelected or {}) do
        local c = w._containers and w._containers[ci]
        if c and c.inventory == S.trashInv then S.slot = k end
    end
    S.cs = S.slot and w._mainContent._colStates and w._mainContent._colStates[S.slot]
    if not S.cs then say("not run: 256 Loot column (the trash can did not open as a column)"); return end
    S.csWas = { S.cs.sortCol, S.cs.sortAsc }
    S.cs.sortCol, S.cs.sortAsc = "cat", true
end)
foldCheck("256 Loot column", ww, colZone, colFolds)
step(10, function()
    if S.cs then S.cs.sortCol, S.cs.sortAsc = S.csWas[1], S.csWas[2]; ZeD_WorldWindow.toggleColumn(S.trashInv, pn) end
end)

-- ===================================================================== put back
step(20, function()
    kbClose(); menuShut(); letGo()
    if openWas then ZeD_ContextList.open = openWas end
    -- the zone (this run's own), the Animals page as found
    local z = zoneObj()
    if z then pcall(function() DesignationZoneAnimal.removeZone(z, true) end) end
    if S.aWas then
        local st = aState()
        st.view, st.zoneName, st.animalRef, st.prevView = S.aWas.view, S.aWas.zoneName, S.aWas.animalRef, S.aWas.prevView
        ww()._animalsRenaming, ww()._animalsRemoveConfirm = false, false
    end
    -- the list's sort and folds
    local c = cMain()
    if S.sortWas then c._sortCol, c._sortAsc = S.sortWas[1], S.sortWas[2] end
    if S.foldsWas then refill(c._collapsedGroups, S.foldsWas) end
    -- the given things, the trash can and its things
    for _, it in ipairs(S.given) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    if S.trash then pcall(function() S.trashInv:removeAllItems(); S.sq:transmitRemoveItemFromSquare(S.trash) end); pcall(function() S.sq:RemoveTileObject(S.trash) end) end
    -- tabs, the Journal page and the container on show
    if S.pageWas then JT.setPage(cw(), S.pageWas) end
    if S.cTab then ZeD_CharacterWindow.openTab(pn, S.cTab) end
    if S.wTab then ZeD_WorldWindow.openTab(pn, S.wTab) end
    local w = ww()
    local st = S.onShow and stops(w, function(e, zz) return zz.zone == "worldContainerStrip" and e.inventory == S.onShow end)[1]
    if st and st.e.onActivate then st.e.onActivate(w, st.e) end
end)
step(40, function()
    p:setGodMod(S.godWas == true)
    if S.speedWas == 0 then setGameSpeed(0) end
    Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
    pcall(function() Focus.releaseFocus(pn) end)
    if S.opened and ZeD_CharacterWindow.isOpen(pn) then ZeD_CharacterWindow.toggleBothPaired(pn) end
    if ZEDQA_LAYOUT_BACK and S.snap then ZEDQA_LAYOUT_BACK(S.snap, "b17i") end
    local left = 0
    for _, it in ipairs(S.given) do if it:getContainer() then left = left + 1 end end
    say("put back: the zone gone " .. tostring(zoneObj() == nil) .. ", given things left " .. left .. ", keyboard up " .. tostring(kbUp()))
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

-- (stepped on each drawn frame: a paused game stops the tick; a button held for a tap is let go before each step)
local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    letGo()
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
