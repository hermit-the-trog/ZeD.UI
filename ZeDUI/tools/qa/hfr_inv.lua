-- ZeDUI/tools/qa/hfr_inv.lua  (Nov 20 2026, QA; tag hfi): the beta 21 hotfix report, CUTS A: the inventory windows and
-- the item card (git 1767d7499 1cc12af9c). Pictures to Zomboid/Screenshots/hfr_A_*.png (the run wrapper moves them to
-- Screenshots/beta21_hotfix_report/). Manifest hotfix_inv.txt (the story stage, gallery_unload.lua, G1, hfr_common.lua).
-- Style Full as found. What it puts back: the things given, the shelf, the stack shut, grid view off, the filter shut,
-- the columns, the windows as found. grep "ZEDQA hfi".
local S = HFR and HFR.init and HFR.init("hfi")
if not S then return end
local Q, IR = S.Q, ZeD.InventoryRenderer
S.A = {}

function S.openStack(ft, on)
    local cnt = S.cc()
    if not cnt then return nil end
    local best = nil
    for _, stk in pairs(cnt._stacks or {}) do
        local ok, full = pcall(function() return stk.rep:getFullType() end)
        if ok and full == ft and stk.count and stk.count > 1 and (not best or stk.count > best.count) then best = stk end
    end
    if not best then return nil end
    cnt._expandedStacks = cnt._expandedStacks or {}
    cnt._expandedStacks[best.key] = on or nil
    for _, cs in ipairs(cnt._colStates or {}) do
        cs.expandedStacks = cs.expandedStacks or cnt._expandedStacks
        cs.expandedStacks[best.key] = on or nil
    end
    return best.count
end
function S.stackShown(ft)
    local cnt = S.cc()
    for _, stk in ipairs(cnt and cnt._openHeads or {}) do
        local ok, full = pcall(function() return stk.rep:getFullType() end)
        if ok and full == ft then return stk.count end
    end
    return nil
end
-- a card on the Character window: seek the row, press it, shoot, press again
function S.cardShot(key, name)
    -- (QA, Nov 20: the item is read when each step runs: this function runs while the queue is built, before the items are given)
    local function IT() return S.A[key] end
    -- (QA, Nov 20: a stacked kind has no row of its own; the kind's stack is opened first, as rt_cards.lua does, and shut after)
    Q.step(10, function()
        S.charTab("loot"); S.seekPos = nil
        local c, ft = S.cc(), nil
        pcall(function() ft = IT():getFullType() end)
        if c and ft then
            c._expandedStacks = c._expandedStacks or {}
            S.stackWas = S.stackWas or {}
            if S.stackWas[ft] == nil then S.stackWas[ft] = c._expandedStacks[ft] or false end
            c._expandedStacks[ft] = true
            for _, cs in ipairs(c._colStates or {}) do cs.expandedStacks = cs.expandedStacks or c._expandedStacks; cs.expandedStacks[ft] = true end
        end
    end)
    Q.waitFor(5, 600, function() return S.seekRow(S.cc(), IT()) end, function(ok)
        if not ok then
            local c, w = S.cc(), S.CW()
            local inFlat, nz, nf, ids = false, 0, 0, {}
            for _, z in ipairs(c and c._hitZones or {}) do nz = nz + 1; if nz <= 6 then ids[#ids + 1] = tostring(z.id) end end
            for _, f in ipairs(c and c._flatItems or {}) do nf = nf + 1; if f == IT() then inFlat = true end end
            local cont = "?"
            pcall(function() cont = tostring(IT():getContainer() == S.p:getInventory()) end)
            Q.say(name .. " DEBUG zones " .. nz .. " [" .. table.concat(ids, " ") .. "], flat " .. nf .. ", in flat " .. tostring(inFlat) .. ", item in main inventory " .. cont .. ", tab " .. tostring(w and w._activeTab) .. ", mcSelected " .. #(w and w._mcSelected or {}) .. ", mainVisible " .. tostring(w and w._mainVisible))
        end
        Q.say(name .. " row " .. tostring(ok) .. ", clicked " .. tostring(ok and S.click(S.cc(), S.zone(S.cc(), IT()))))
    end)
    Q.waitFor(10, 300, function() return S.cardOn(IT()) end, function(ok) Q.say(name .. " card out " .. tostring(ok)); S.clearChar() end)
    Q.still(10, function()
        if S.cardOn(IT()) then S.shot(name) else Q.notTaken(name, "the card did not open") end
    end)
    Q.step(5, function() if S.cardOn(IT()) then S.click(S.cc(), S.zone(S.cc(), IT())) end end)
end

-- ===================================================================== start
Q.step(5, function()
    S.start0()
    S.was.grid = IR.isGridKey("player")
    G1.fillShelf(Q)
    S.A.hammer = S.add("Base.Hammer")
    S.A.lighter = S.add("Base.Lighter")
    S.add("Base.Matches")
    S.A.apple = S.add("Base.Apple"); S.add("Base.Apple"); S.add("Base.Apple")
    S.A.bag = S.add("Base.Bag_Schoolbag")
    pcall(function() local bi = S.A.bag:getItemContainer(); bi:AddItem("Base.Hammer"); bi:AddItem("Base.Pop") end)
    -- (A_card_garment, QA Nov 20: a worn garment is not a row of the Loot list, so a garment is carried and its card opened from the list)
    for _, ft in ipairs({ "Base.Jacket_Padded", "Base.Jumper_RoundNeck", "Base.Shirt_FormalWhite_ShortSleeve", "Base.Tshirt_DefaultTEXTURE" }) do
        if not S.A.shirt then S.A.shirt = S.add(ft); if S.A.shirt then Q.say("garment given: " .. ft) end end
    end
    Q.say("given: hammer " .. tostring(S.A.hammer ~= nil) .. ", lighter " .. tostring(S.A.lighter ~= nil) .. ", bag " .. tostring(S.A.bag ~= nil) .. ", shirt " .. tostring(S.A.shirt ~= nil))
    pcall(function() IR.setGridKey("player", false) end)
end)
Q.zoomTo(1.0)

-- A_char_list_title (also the World window's title only)
Q.step(10, function()
    G1.tp(S.P.stock, "SE")
    S.openPair()
end)
Q.step(60, function()
    S.charTab("loot"); S.worldTab("loot")
    if G1.shelf then S.WWm.selectContainer(G1.shelf.inv, 120, S.pn) end
end)
Q.waitFor(10, 600, function() return S.oneSource() end, function() end)
Q.step(20, function() if G1.shelf then S.WWm.selectContainer(G1.shelf.inv, 120, S.pn) end; S.clearChar() end)
Q.still(10, function() S.shot("A_char_list_title") end)

-- A_stack_open: the apples' stack opened
Q.step(10, function() Q.say("apple stack opened: " .. tostring(S.openStack("Base.Apple", true))) end)
Q.waitFor(10, 300, function() return S.stackShown("Base.Apple") ~= nil end, function() end)
Q.step(20, function() S.clearChar() end)
Q.still(10, function()
    local n = S.stackShown("Base.Apple")
    if n and n >= 3 then S.shot("A_stack_open") else Q.notTaken("A_stack_open", "no open apple stack (" .. tostring(n) .. ")") end
end)
Q.step(5, function() S.openStack("Base.Apple", false) end)

-- A_two_picked: two rows picked in the Character list
Q.step(10, function()
    local cnt = S.cc()
    local n = 0
    for _, it in ipairs(cnt and cnt._flatItems or {}) do
        if n < 2 and it ~= S.A.bag then cnt._selectedItems = cnt._selectedItems or {}; cnt._selectedItems[it] = true; n = n + 1 end
    end
    if cnt then cnt._padMarks = true end
    Q.say("rows picked " .. n)
end)
Q.step(20, function() S.clearChar() end)
Q.still(10, function()
    local w = S.CW()
    local s = w and w.getStatusLine and w:getStatusLine() or "?"
    Q.say("foot line: " .. tostring(s))
    S.shot("A_two_picked")
end)
Q.step(5, function()
    local cnt = S.cc()
    if cnt then ZeD.InventoryRenderer.padClearMarksOf(cnt); cnt._selectedItems = {} end
end)

-- A_grid_view: the Character list as a grid, the Filter bar open, the sort keys under it
Q.step(10, function() IR.setGridKey("player", true) end)
Q.step(30, function()
    local c = S.cc()
    local z = S.zoneStarts(c, "view:filter:")
    Q.say("filter button " .. tostring(z ~= nil))
    if z then S.click(c, z) end
end)
Q.step(40, function() S.clearChar() end)
Q.still(10, function() S.shot("A_grid_view") end)
Q.step(10, function()
    local c = S.cc()
    local z = S.zone(c, "view:fbar:clear")
    local f = c and c._zedFilter
    if f and f.open then
        local z2 = S.zoneStarts(c, "view:filter:")
        if z2 then S.click(c, z2) end
    end
    pcall(function() IR.setGridKey("player", S.was.grid == true) end)
end)

-- A_bag_alone: the schoolbag's column alone (the main inventory's off), the load back in the title bar
Q.step(10, function()
    local w = S.CW()
    local bagInv = nil
    pcall(function() bagInv = S.A.bag:getItemContainer() end)
    S.bagInv = bagInv
    Q.say("bag column on " .. tostring(bagInv ~= nil and S.CWm.toggleColumn(bagInv, S.pn)))
end)
Q.step(20, function()
    Q.say("main column off " .. tostring(S.CWm.toggleColumn(S.p:getInventory(), S.pn)))
end)
Q.step(40, function()
    local w = S.CW()
    Q.say("mcSelected " .. #(w and w._mcSelected or {}) .. ", mainVisible " .. tostring(w and w._mainVisible))
    S.clearChar()
end)
Q.still(10, function()
    local w = S.CW()
    if w and not w._mainVisible then S.shot("A_bag_alone") else Q.notTaken("A_bag_alone", "the main column still shows") end
end)
Q.step(10, function()
    local w = S.CW()
    if w and not w._mainVisible then S.CWm.toggleColumn(S.p:getInventory(), S.pn) end
end)
Q.step(20, function()
    if S.bagInv then S.CWm.toggleColumn(S.bagInv, S.pn) end
end)
Q.waitFor(10, 600, function() return S.oneSource() end, function() end)

-- A_ground_empty: the World window on the floor, nothing on it
Q.step(10, function()
    local ww = S.WW()
    S.floorInv = nil
    for _, e in ipairs((ww and ww._containers) or {}) do
        if not S.floorInv and e.inventory then
            local ty = nil
            pcall(function() ty = e.inventory:getType() end)
            if e.isFloor or ty == "floor" then S.floorInv = e.inventory end
        end
    end
    Q.say("floor container " .. tostring(S.floorInv ~= nil))
    if S.floorInv then pcall(S.WWm.selectContainer, S.floorInv, 60, S.pn) end
end)
Q.step(40, function() S.clearChar() end)
Q.still(10, function()
    local wc = S.wc()
    local n = #(wc and wc._flatItems or {})
    Q.say("floor rows " .. n)
    if S.floorInv and n == 0 then S.shot("A_ground_empty") else Q.notTaken("A_ground_empty", "floor " .. tostring(S.floorInv ~= nil) .. ", rows " .. n) end
end)
Q.step(10, function() if G1.shelf then S.WWm.selectContainer(G1.shelf.inv, 120, S.pn) end end)

-- item cards: gray labels (hammer, lighter), a garment, food
S.cardShot("hammer", "A_card_labels_gray")
S.cardShot("shirt", "A_card_garment")
S.cardShot("apple", "A_card_food_hunger")

-- the tabs of the Character window: Health, Thermal, Identity, Journal
for _, t in ipairs({ { "health", "A_health_body_figure" }, { "thermal", "A_thermal_body_figure" }, { "identity", "A_identity_no_header" }, { "journal", "A_journal_log" } }) do
    Q.step(10, function() S.charTab(t[1]) end)
    Q.step(60, function() S.clearChar() end)
    Q.still(10, function()
        local w = S.CW()
        if w and w._activeTab == t[1] then S.shot(t[2]) else Q.notTaken(t[2], "the tab did not open") end
    end)
end
-- A_craft_microwave: a microwave on the Craft tab, no "Crafting" row
Q.step(10, function()
    S.charTab("loot")
    S.micro = nil
    local sq = S.freeSq()
    if sq then
        pcall(function()
            local obj = IsoStove.new(getCell(), sq, getSprite("appliances_cooking_01_24"))
            pcall(function() obj:createContainersFromSpriteProperties() end)
            sq:AddSpecialObject(obj)
            if obj:getObjectIndex() < 0 then pcall(function() sq:AddTileObject(obj) end) end
            S.micro, S.microSq = obj, sq
        end)
    end
    Q.say("microwave placed " .. tostring(S.micro ~= nil))
end)
Q.step(30, function()
    S.microOpen = S.micro ~= nil and ZeD.Stations and ZeD.Stations.open(S.p, S.micro) or false
    Q.say("microwave on the Craft tab " .. tostring(S.microOpen))
end)
Q.step(60, function() S.clearChar() end)
Q.still(10, function()
    if S.microOpen then S.shot("A_craft_microwave") else Q.notTaken("A_craft_microwave", "the microwave did not open") end
end)
Q.step(10, function()
    pcall(function() ZeD.Stations.unbind(S.p) end)
    if S.micro and S.microSq then pcall(function() S.microSq:transmitRemoveItemFromSquare(S.micro) end) end
    S.micro = nil
    S.worldTab("loot")
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    if S.micro and S.microSq then pcall(function() S.microSq:transmitRemoveItemFromSquare(S.micro) end) end
    pcall(function() IR.setGridKey("player", S.was.grid == true) end)
    S.openStack("Base.Apple", false)
    S.takeMade()
    pcall(function()
        local c = S.cc()
        for ft, v in pairs(S.stackWas or {}) do if c and c._expandedStacks then c._expandedStacks[ft] = (v ~= false) and v or nil end end
    end)
    G1.shelfBack(Q)
    G1.glassesBack(Q)
end)
Q.step(20, function()
    S.openPair()
    S.charTab("loot"); S.worldTab("loot")
    S.back0()
end)
Q.step(30, function()
    if not S.was.pairOpen then S.closePair() end
    pcall(function() Mouse.setCursorVisible(true) end)
    Q.say("put back")
end)
Q.start()
