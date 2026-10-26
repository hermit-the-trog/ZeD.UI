-- ZeDUI/tools/qa/zedqa_read_marks.lua  (Oct 26 2026)
-- Read marks in the item lists (mockup zed_read_marks_v1, style B; approved Oct 26 2026). The character gets
-- Mechanics 3, First Aid 0, Cooking 2, Fishing 3, Carpentry 0 for the run, and these in the bags:
--   Mechanics II        140 of its pages read        part read, NEXT LEVEL (Mechanics 4)
--   First Aid I         nothing read                  unread, NEXT LEVEL (First Aid 1)
--   Cooking III         nothing read                  unread, no tag (levels 5 to 6, you have 2)
--   Fishing I           nothing read                  read: below your level (Fishing 3)
--   Carpentry I         every page read               read
--   Good Cooking mag    one of its two recipes known  part read ("1 of 2 known")
--   Generators mag      its recipe known              read ("Known")
--   a map, a VHS tape (as this character has them), a pencil (no mark)
-- Checks each status, then captures the list (COND column), the hover text (the pointer stood in on the list), the
-- grid, and the list with "Dim read items" on. Every level, page count, recipe, item, view and setting goes back.
-- Screenshots zqa_rm_*.png; grep "ZEDQA rm".
local p = getPlayer()
local pn = p:getPlayerNum()
local RM, IR = ZeD.ReadMarks, ZeD.InventoryRenderer
local function say(s) print("ZEDQA rm " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_rm_" .. n .. ".png") end) end
if not (RM and RM.state and ZeD.Settings and ZeD.Settings.dimReadOption) then say("ERR the new code is not loaded"); say("DONE"); return end
local inv = p:getInventory()
local function cw() return ZeD_CharacterWindow.getWindow() end
local function content() local w = cw(); return w and w._mainContent end
local function tab(id)
    local w = cw(); local strip = w and w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end
local Q, qi, wait = {}, 1, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

-- what goes back at the end
local LEVELS = { { Perks.Mechanics, 3 }, { Perks.Doctor, 0 }, { Perks.Cooking, 2 }, { Perks.Fishing, 3 }, { Perks.Woodwork, 0 } }
local was = { levels = {}, pages = {}, recipes = {}, grid = IR.isGridKey("player"), dim = ZeD.Settings.dimReadOption:getValue() }
local given, items = {}, {}
local function give(key, full)
    local it = inv:AddItem(full)
    given[#given + 1] = it
    items[key] = it
    return it
end
local function setPages(full, n)
    if was.pages[full] == nil then was.pages[full] = p:getAlreadyReadPages(full) end
    p:setAlreadyReadPages(full, n)
end
local function learn(r)
    local kr = p:getKnownRecipes()
    if not kr:contains(r) then kr:add(r); was.recipes[#was.recipes + 1] = r end
end

local listWas = nil
step(5, function()
    for _, l in ipairs(LEVELS) do was.levels[#was.levels + 1] = { l[1], p:getPerkLevel(l[1]) }; p:setPerkLevelDebug(l[1], l[2]) end
    give("mech2", "Base.BookMechanic2"); give("aid1", "Base.BookFirstAid1"); give("cook3", "Base.BookCooking3")
    give("fish1", "Base.BookFishing1"); give("carp1", "Base.BookCarpentry1")
    give("magCook", "Base.CookingMag1"); give("magGen", "Base.ElectronicsMag4")
    give("map", "Base.MuldraughMap"); give("vhs", "Base.VHS_Retail"); give("pencil", "Base.Pencil")
    setPages("Base.BookMechanic2", 140)
    setPages("Base.BookFirstAid1", 0); setPages("Base.BookCooking3", 0); setPages("Base.BookFishing1", 0)
    setPages("Base.BookCarpentry1", items.carp1:getNumberOfPages())
    -- the magazines: Good Cooking teaches two (one known here), How to Use Generators one (known here)
    local lr = items.magCook:getLearnedRecipes()
    say("Good Cooking teaches " .. tostring(lr and lr:size()) .. "; the generators magazine " .. tostring(items.magGen:getLearnedRecipes() and items.magGen:getLearnedRecipes():size()))
    local kr = p:getKnownRecipes()
    if lr and lr:size() >= 2 then
        learn(lr:get(0))
        for i = 1, lr:size() - 1 do
            local r = lr:get(i)
            if kr:contains(r) then kr:remove(r); was.recipes[#was.recipes + 1] = "-" .. tostring(r) end
        end
    end
    local lg = items.magGen:getLearnedRecipes()
    for i = 0, (lg and lg:size() or 0) - 1 do learn(lg:get(i)) end
    RM.clear()
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
end)
step(20, function()
    tab("loot")
    IR.setGridKey("player", false)
    -- the list sorted by category with every other category folded, so the test items are all on screen
    local c = content()
    listWas = { sortCol = c._sortCol, sortAsc = c._sortAsc, collapsed = c._collapsedGroups }
    local mine = {}
    for _, k in ipairs({ "mech2", "magCook" }) do mine[IR.catKey(items[k])] = true end   -- the books and the magazines
    for _, it in pairs(items) do if it:IsLiterature() and not it:IsMap() then mine[IR.catKey(it)] = true end end
    local folded = {}
    local all = inv:getItems()
    for i = 0, all:size() - 1 do local k = IR.catKey(all:get(i)); if not mine[k] then folded[k] = true end end
    c._sortCol, c._sortAsc, c._collapsedGroups = "cat", true, folded
end)
-- (the books and magazines sort last: the list scrolled to its end)
local function toEnd() local c = content(); if c and c._scroll then c._scroll:setScrollPos(1) end end
step(10, toEnd)

-- the statuses
local function expect(key, st, word, nextLv, tag)
    local s = RM.state(p, items[key])
    local got = s and (s.st .. " / " .. s.word .. " / " .. tostring(s.next)) or "nil"
    if st == nil then check(s == nil, tag .. ": no mark (" .. got .. ")"); return end
    check(s ~= nil and s.st == st and (word == nil or s.word == word) and s.next == nextLv, tag .. " (" .. got .. ")")
    if s then say("  hover: " .. table.concat(s.lines or {}, " || ")) end
end
step(30, function()
    RM.clear()
    expect("mech2", "p", ZeD.tr("UI_ZeD_Read_Pages", 140, items.mech2:getNumberOfPages()), PerkFactory.getPerk(Perks.Mechanics):getName() .. " 4", "Mechanics II: part read, next level")
    expect("aid1", "u", ZeD.tr("UI_ZeD_Read_Unread"), PerkFactory.getPerk(Perks.Doctor):getName() .. " 1", "First Aid I: unread, next level")
    expect("cook3", "u", ZeD.tr("UI_ZeD_Read_Unread"), nil, "Cooking III: unread, too high for a tag")
    expect("fish1", "r", ZeD.tr("UI_ZeD_Read_Read"), nil, "Fishing I: below your level counts as read")
    expect("carp1", "r", ZeD.tr("UI_ZeD_Read_Read"), nil, "Carpentry I: every page read")
    expect("magCook", "p", nil, nil, "Good Cooking: some recipes known")
    expect("magGen", "r", ZeD.tr("UI_ZeD_Read_Known"), nil, "Generators magazine: its recipe known")
    -- (the map and the tape: whatever this character has seen; the mark is there, read or not)
    local sm, sv = RM.state(p, items.map), RM.state(p, items.vhs)
    check(sm ~= nil, "the map has a mark (" .. tostring(sm and sm.st .. " / " .. sm.word) .. ")")
    say("the tape: " .. tostring(sv and (sv.st .. " / " .. sv.word .. " / " .. table.concat(sv.lines, " || "))) .. " (recorded media " .. tostring(items.vhs:isRecordedMedia()) .. ")")
    expect("pencil", nil, nil, nil, "the pencil")
    local s = RM.state(p, items.cook3)
    check(s and s.lines and s.lines[#s.lines]:find(ZeD.tr("UI_ZeD_Read_ForLevels", PerkFactory.getPerk(Perks.Cooking):getName(), 5, 6, 2), 1, true) ~= nil,
        "Cooking III: the hover names its levels and yours")
    local c = content()
    say("COND column " .. tostring(c._colWidths and c._colWidths.cond) .. " px (old default " .. math.floor(50 * ZeD.T.scale) .. "); list " .. c:getWidth() .. " wide; rows placed " .. tostring(c._itemRenderYMap and c._itemRenderYMap[items.mech2]))
    shot("1_list")
end)
-- the hover text over Mechanics II (the pointer stood in on the list: its own getMouseX / getMouseY)
local hoverItem = nil
local function pointAtRow(item)
    local c = content()
    local y = c._itemRenderYMap and c._itemRenderYMap[item]
    if y then
        local mx, my = (c._renderXOffset or 0) + ZeD.T.px(60), y + math.floor(ZeD.T.rowH / 2)
        c.getMouseX = function() return mx end
        c.getMouseY = function() return my end
    end
    say("row at y " .. tostring(y) .. " of a list " .. c:getHeight() .. " high")
    return (y and y > 0 and y < c:getHeight()) and y or nil
end
step(5, function() hoverItem = items.magCook; check(pointAtRow(hoverItem) ~= nil, "Good Cooking's row is on screen") end)
step(90, function()
    local c = content()
    local hc = c._gridHintCand
    say("hint: since " .. tostring(c._gridHintSince) .. " drawn " .. tostring(c._readHintAt) .. " now " .. getTimestampMs())
    check(c._readHintAt and getTimestampMs() - c._readHintAt < 1000, "the read hover text is drawn")
    check(hc and hc.read ~= nil and c._gridHintKey == hoverItem, "the pointer over Good Cooking's row: its read hover text (" .. tostring(hc and hc.text) .. ", key " .. tostring(c._gridHintKey) .. ")")
    shot("2_hover_part_known")
end)
step(5, function() hoverItem = items.mech2; pointAtRow(hoverItem) end)
step(90, function() shot("3_hover_next_level") end)
step(5, function() local c = content(); c.getMouseX, c.getMouseY = nil, nil end)
-- dim read items
step(5, function() ZeD.Settings.dimReadOption:setValue(2) end)
step(20, function()
    check(RM.dimOn() == true, "Dim read items on")
    shot("4_list_dim")
    ZeD.Settings.dimReadOption:setValue(1)
end)
-- the grid
step(5, function() IR.setGridKey("player", true) end)
step(5, toEnd)
step(40, function()
    local c = content()
    check(c._gridCell ~= nil, "the grid is on (cell " .. tostring(c._gridCell) .. ")")
    shot("5_grid")
    local xm, ym = c._itemRenderXMap, c._itemRenderYMap
    local x, y = xm and xm[items.mech2], ym and ym[items.mech2]
    if x and y then
        local mx, my = x + math.floor(c._gridCell / 2), y + math.floor(c._gridCell / 2)
        c.getMouseX = function() return mx end
        c.getMouseY = function() return my end
    end
end)
step(90, function()
    local c = content()
    local hc = c._gridHintCand
    check(hc and hc.read ~= nil, "the grid cell's hover carries the read status")
    say("grid hint: since " .. tostring(c._gridHintSince) .. " drawn " .. tostring(c._readHintAt) .. " now " .. getTimestampMs())
    shot("6_grid_hover")
    c.getMouseX, c.getMouseY = nil, nil
end)
-- the column hidden (a narrow window): the dot at the end of the name
step(5, function() IR.setGridKey("player", false); content()._compactMode = true end)
step(5, toEnd)
step(20, function() shot("7_list_narrow"); content()._compactMode = nil end)
-- a wider window: the COND column with room for the longer words
local wWas = nil
step(5, function() local w = cw(); wWas = w:getWidth(); w:setWidth(wWas + ZeD.T.px(260)) end)
step(5, toEnd)
step(40, function() say("window " .. tostring(wWas) .. " -> " .. cw():getWidth() .. "; list " .. content():getWidth()); shot("8_list_wide") end)
step(5, function() if wWas then cw():setWidth(wWas) end end)

-- ZeD setup's switches: NEXT LEVEL off (no tag, the marks stay), then read marks off (no marks, COND as before)
local swWas = { m = ZeD.Settings.readMarksOption:getValue() or 2, n = ZeD.Settings.readNextOption:getValue() or 2 }
step(5, function() ZeD.Settings.readNextOption:setValue(1); toEnd() end)
step(20, function()
    check(RM.state(p, items.mech2) ~= nil and not RM.nextOn(), "NEXT LEVEL off: the mark stays, the tag goes")
    shot("9_next_off")
    ZeD.Settings.readMarksOption:setValue(1)
end)
step(20, function()
    RM.clear()
    local c = content()
    check(RM.state(p, items.mech2) == nil and RM.state(p, items.carp1) == nil, "read marks off: no marks")
    check(c._colWidths and c._colWidths.cond == math.floor(50 * ZeD.T.scale), "read marks off: COND at its old width (" .. tostring(c._colWidths and c._colWidths.cond) .. ")")
    toEnd()
end)
step(10, function() shot("10_marks_off") end)
step(5, function() ZeD.Settings.readMarksOption:setValue(swWas.m); ZeD.Settings.readNextOption:setValue(swWas.n) end)

-- back as it was
step(5, function()
    local c = content()
    c._compactMode = nil
    if listWas then c._sortCol, c._sortAsc, c._collapsedGroups = listWas.sortCol, listWas.sortAsc, listWas.collapsed end
    IR.setGridKey("player", was.grid)
    ZeD.Settings.dimReadOption:setValue(was.dim or 1)
    for _, l in ipairs(was.levels) do p:setPerkLevelDebug(l[1], l[2]) end
    for full, n in pairs(was.pages) do p:setAlreadyReadPages(full, n) end
    local kr = p:getKnownRecipes()
    for _, r in ipairs(was.recipes) do
        if type(r) == "string" and r:sub(1, 1) == "-" then kr:add(r:sub(2)) else kr:remove(r) end
    end
    for _, it in ipairs(given) do local ct = it:getContainer(); if ct then ct:Remove(it) end end
    RM.clear()
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local function onTick()
    if not Q[qi] then Events.OnTick.Remove(onTick); return end
    wait = wait + 1
    if wait < Q[qi].n then return end
    wait = 0
    local ok, e = pcall(Q[qi].fn)
    if not ok then fails = fails + 1; say("ERR step " .. qi .. " " .. tostring(e)) end
    qi = qi + 1
end
Events.OnTick.Add(onTick)
say("start")
