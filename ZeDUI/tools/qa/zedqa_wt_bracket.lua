-- ZeDUI/tools/qa/zedqa_wt_bracket.lua  (Oct 29 2026)
-- In game on the ZeD-QA save: a stack's row shows its total weight in brackets
-- ("Apple x5 ... (1.0)"); open the stack and each row under it shows its own, as a
-- single item does. Five of a kind and one single thing go in the character's bag
-- (Character window Loot) and on the ground (World window Loot). Each content's
-- drawText is wrapped for a few frames, and the weight text drawn on the stack's
-- row / cell and the single's is read back by its place: in the list, the stack
-- opened, in the grid, at Small and at Large, with the bag beside a worn pack (two
-- narrow columns), and with the list's WT column dragged down to the unit's width
-- (the total drops its decimal, "(1)"). The expected total is summed here from the
-- container, as vanilla's inventory sums a stack. Every weight must sit inside its
-- column / cell and clear of the name; at Small the list keeps Cat and Cond.
-- Everything is put back (items, pack, columns, grid choices, the WT width, the
-- text size, each list's sort and scroll).
-- A line with FAIL is a check that did not hold. grep "ZEDQA wtb";
-- screenshots Screenshots/zqa_wtb_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local IR = ZeD.InventoryRenderer
local function say(s) print("ZEDQA wtb " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_wtb_" .. n .. ".png") end) end
local function cwin() return ZeD_CharacterWindow.getWindow() end
local function wwin() return ZeD_WorldWindow.getWindow() end
local function contentOf(k) local w = (k == "char") and cwin() or wwin(); return w and w._mainContent end

local fails = 0
local function fail(s) fails = fails + 1; say("FAIL " .. s) end
local given, floorItems = {}, {}
local pack, sqWorld, floor, oldWorldInv
local openedPair = false
local gridTouched, gridOld, NIL = {}, {}, {}
local orig = ZeD.currentSize
local stackT, singleT = {}, {}   -- per window: the item type of the stack / the single

-- ---- items: types none of the window's container already holds
local STACK_TYPES  = { "Base.Apple", "Base.Orange", "Base.Peach", "Base.Pear", "Base.Lemon" }
local SINGLE_TYPES = { "Base.Saucepan", "Base.Crowbar", "Base.Saw", "Base.Hammer" }
local function held(inv, ft)
    local n = 0
    local items = inv:getItems()
    for i = 0, items:size() - 1 do if items:get(i):getFullType() == ft then n = n + 1 end end
    return n
end
local function freeType(inv, list) for _, ft in ipairs(list) do if held(inv, ft) == 0 then return ft end end end

-- the expected words: the unit weight of one, and the stack's total (vanilla's sum)
local function f1(w) return string.format("%.1f", w) end
local function expectFor(inv, ft)
    local total, n = 0, 0
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it:getFullType() == ft and not it:isHidden() then
            n = n + 1; total = total + it:getUnequippedWeight()
        end
    end
    return n, total
end

-- ---- capture: every drawText of a content, with where it went (hooked again
-- when the window builds a new content, as a text size change may)
local cap, hooked, capOn = { char = {}, world = {} }, {}, false
local function hook(k)
    local c = contentOf(k)
    if not c or (hooked[k] and hooked[k].c == c) then return end
    if hooked[k] then hooked[k].c.drawText = hooked[k].had end
    local had = rawget(c, "drawText")
    local base = c.drawText
    hooked[k] = { c = c, had = had }
    c.drawText = function(self, s, x, y, r, g, b, a, font)
        if capOn then local t = cap[k]; t[#t + 1] = { s = tostring(s), x = x, y = y, font = font } end
        return base(self, s, x, y, r, g, b, a, font)
    end
end
local function unhook()
    for _, h in pairs(hooked) do h.c.drawText = h.had end
    hooked = {}
end

-- the column that shows inv: { renderX, renderW, flatItems, childParent, ymap,
-- xmap, cell, scroll } and the number of columns. A single list keeps all of it
-- on the content (its _inventory); side by side, each colState keeps its own.
local function colFor(c, inv)
    local css = c._colStates or {}
    if #css > 1 then
        for _, cs in ipairs(css) do
            if cs.inventory == inv then
                return { renderX = cs.renderX, renderW = cs.renderW, flatItems = cs.flatItems, childParent = cs.childParent,
                         ymap = cs.itemRenderYMap, xmap = cs.itemRenderXMap, cell = cs.gridCell, scroll = cs.scroll }, #css
            end
        end
        return nil, #css
    end
    if c._inventory == inv then
        return { renderX = 0, renderW = c:getWidth(), flatItems = c._flatItems, childParent = c._childParent,
                 ymap = c._itemRenderYMap, xmap = c._itemRenderXMap, cell = c._gridCell, scroll = c._scroll }, 1
    end
    return nil, 1
end
local function invOf(k) return (k == "char") and p:getInventory() or floor end
-- scroll the column so item's row / cell sits a third of the way down
-- (renderY = contentTop + logicalY - scrollOffset, as renderItemList draws)
local function reveal(k, ft)
    local c = contentOf(k)
    local col = c and colFor(c, invOf(k))
    local s = col and col.scroll
    if not (s and s.visible and s.barSizeRatio and s.barSizeRatio > 0) then return end
    local item
    for _, it in ipairs(col.flatItems or {}) do if it:getFullType() == ft then item = it; break end end
    local y = item and col.ymap and col.ymap[item]
    if not y then return end
    local vis = s.height
    local range = vis / s.barSizeRatio - vis
    if range <= 0 then return end
    local logical = y - s.y + math.floor(s.scrollPos * range)
    s:setScrollPos((logical - math.floor(vis / 3)) / range)
end
local function repOf(col, ft)
    for _, it in ipairs(col.flatItems or {}) do
        if it:getFullType() == ft and not (col.childParent and col.childParent[it]) then return it end
    end
end
local isWt = function(s) return s:match("^%d+%.%d$") or s:match("^%(%d+%.%d%)$") or s:match("^%(%d+%)$") end

-- the weight drawn for item (and the name's right end in a list row)
local function drawnFor(k, col, item, grid)
    local y0 = col.ymap and col.ymap[item]
    if not y0 then return nil, "no row" end
    local x0, x1, y1
    if grid then
        local cx = col.xmap and col.xmap[item]
        if not cx then return nil, "no cell" end
        x0, x1, y1 = cx, cx + (col.cell or 0), y0 + (col.cell or 0)
    else
        x0, x1, y1 = col.renderX or 0, (col.renderX or 0) + col.renderW, y0 + ZeD.T.rowH
    end
    local wt, nameR
    local nm = string.sub(item:getName() or "", 1, 3)
    for _, e in ipairs(cap[k]) do
        if e.y >= y0 and e.y < y1 and e.x >= x0 - 1 and e.x < x1 then
            if isWt(e.s) then wt = e
            elseif not grid and nm ~= "" and string.sub(e.s, 1, 3) == nm then
                nameR = e.x + ZeD.TM:MeasureStringX(e.font or ZeD.T.fontF2, e.s)
            end
        end
    end
    if not wt then return nil, "no weight drawn" end
    wt.r = wt.x + ZeD.TM:MeasureStringX(wt.font or ZeD.T.fontF3, wt.s)
    return wt, nameR, x1
end

-- one window's stack, or its single: the words and the fit
local function checkOne(k, tag, grid, mode, which)
    local c = contentOf(k)
    local inv = invOf(k)
    if not (c and inv) then fail(tag .. " " .. k .. ": no content"); return end
    local col, ncols = colFor(c, inv)
    if not col then fail(tag .. " " .. k .. ": the container is not shown (" .. ncols .. " columns)"); return end
    local n, total = expectFor(inv, stackT[k])
    local rep = repOf(col, stackT[k])
    local single = repOf(col, singleT[k])
    if not (rep and single) then fail(tag .. " " .. k .. ": stack " .. tostring(rep) .. " single " .. tostring(single)); return end
    local unitS = f1(rep:getUnequippedWeight())
    local full = "(" .. f1(total) .. ")"
    local whole = "(" .. string.format("%.0f", total) .. ")"
    if which == "stack" then
    local w, nameR, right = drawnFor(k, col, rep, grid)
    if not w then fail(tag .. " " .. k .. " stack: " .. tostring(nameR)) else
        local okWords = (w.s == full) or (mode ~= "wide" and (w.s == whole or w.s == unitS))
        say(string.format("%s %s stack %s x%d: drew \"%s\" (expect \"%s\"%s) at x %d..%d of %d, name ends %s, columns %d",
            tag, k, rep:getName(), n, w.s, full, mode ~= "wide" and (" or \"" .. whole .. "\" / \"" .. unitS .. "\"") or "",
            w.x, w.r, right, tostring(nameR and math.floor(nameR)), ncols))
        if mode == "narrow" and w.s ~= whole then fail(tag .. " " .. k .. ": the total did not shorten to \"" .. whole .. "\" in the narrow WT column") end
        if not okWords then fail(tag .. " " .. k .. ": stack drew \"" .. w.s .. "\"") end
        if w.r > right + 1 then fail(tag .. " " .. k .. ": the stack's weight runs past its " .. (grid and "cell" or "column")) end
        if nameR and nameR > w.x then fail(tag .. " " .. k .. ": the stack's weight overlaps its name") end
    end
    -- the bracket takes its room from the name: in the default-width list Cat and Cond still show
    if not grid then
        local hdr = {}
        for _, e in ipairs(cap[k]) do hdr[string.lower(e.s)] = true end
        local catOn = hdr[string.lower(ZeD.tr("UI_ZeD_Inv_ColCat"))] or false
        local condOn = hdr[string.lower(ZeD.tr("UI_ZeD_Inv_ColCond"))] or false
        say(string.format("%s %s headers: cat %s, cond %s", tag, k, tostring(catOn), tostring(condOn)))
        if tag == "small list" and not (catOn and condOn) then fail(tag .. " " .. k .. ": a column dropped for the bracket") end
    end
    return
    end
    local sw, sNameR, sRight = drawnFor(k, col, single, grid)
    local sUnit = f1(single:getUnequippedWeight())
    if not sw then fail(tag .. " " .. k .. " single: " .. tostring(sNameR)) else
        say(string.format("%s %s single %s: drew \"%s\" (expect \"%s\")", tag, k, single:getName(), sw.s, sUnit))
        if sw.s ~= sUnit then fail(tag .. " " .. k .. ": the single drew \"" .. sw.s .. "\"") end
        if sw.r > sRight + 1 then fail(tag .. " " .. k .. ": the single's weight runs past") end
        if sNameR and sNameR > sw.x then fail(tag .. " " .. k .. ": the single's weight overlaps its name") end
    end
end
local function capStart() hook("char"); hook("world"); cap.char, cap.world = {}, {}; capOn = true end

-- the stack opened (as its chevron does): its row keeps the total, each row under it draws its own weight
local function openStack(k, on)
    local c = contentOf(k)
    if not c then return end
    local cs = c._colStates and c._colStates[1]
    local t = (cs and cs.expandedStacks) or c._expandedStacks
    if t then t[stackT[k]] = on or nil end
end
local function checkOpen(k, tag)
    local c = contentOf(k)
    local col = c and colFor(c, invOf(k))
    if not col then fail(tag .. " " .. k .. ": the container is not shown"); return end
    local n, total = expectFor(invOf(k), stackT[k])
    local rep = repOf(col, stackT[k])
    local w = rep and drawnFor(k, col, rep, false)
    local full = "(" .. f1(total) .. ")"
    if not (w and w.s == full) then fail(tag .. " " .. k .. ": the open stack's row drew " .. tostring(w and w.s) .. ", not " .. full) end
    local kids, own = 0, 0
    for _, it in ipairs(col.flatItems or {}) do
        if col.childParent and col.childParent[it] and it:getFullType() == stackT[k] then
            kids = kids + 1
            local cw = drawnFor(k, col, it, false)
            if cw and cw.s == f1(it:getUnequippedWeight()) then own = own + 1
            else fail(tag .. " " .. k .. ": a row under the stack drew " .. tostring(cw and cw.s)) end
        end
    end
    say(string.format("%s %s: the row \"%s\", %d rows under it, %d with their own weight", tag, k, tostring(w and w.s), kids, own))
    if kids ~= n - 1 then fail(tag .. " " .. k .. ": " .. kids .. " rows under the stack, " .. (n - 1) .. " expected") end
end

-- ---- views and columns
local function gridStore()
    local md = p:getModData()
    md.ZeD_GridViews = md.ZeD_GridViews or {}
    return md.ZeD_GridViews
end
local function setView(grid)
    local st = gridStore()
    for _, inv in ipairs({ p:getInventory(), floor }) do
        local key = inv and IR.containerKey(inv, p)
        if key then
            if not gridTouched[key] then gridTouched[key] = true; gridOld[key] = (st[key] == nil) and NIL or st[key] end
            IR.setGridKey(key, grid)
        end
    end
end
local function colOn(win, inv)
    for i, c in ipairs(win._containers or {}) do
        if c.inventory == inv then
            for _, j in ipairs(win._mcSelected or {}) do if j == i then return true end end
            return false
        end
    end
    return false
end
local function tabLoot()
    local w = cwin()
    local strip = w and w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:loot" then if w._activeTab ~= "loot" then strip:onMouseDown(z.x + 2, z.y + 2) end; break end
    end
    pcall(function() ZeD_WorldWindow.openTab(pn, "loot") end)
end
local function sortName()
    for _, k in ipairs({ "char", "world" }) do
        local c = contentOf(k)
        if c then
            c._sortCol, c._sortAsc = "name", true
            for _, cs in ipairs(c._colStates or {}) do cs.sortCol, cs.sortAsc = "name", true; cs.expandedStacks = {} end
            c._expandedStacks = {}
        end
    end
end

-- ---- the run
local steps, si, wait = {}, 1, 0
local dead = false
local function step(n, fn) steps[#steps + 1] = { n, fn } end
local function abort(msg) say("ERR " .. msg); dead = true; si = #steps - 1 end
local oldWt
local keep = {}   -- each list's sort and scroll as found, put back at the end (the next script reads the top of the list)

step(1, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    p:setGodMod(true)
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn); openedPair = true end
end)
step(30, function()
    if not (cwin() and wwin()) then abort("the windows are not open"); return end
    tabLoot()
    local inv = p:getInventory()
    floor = ZeD_WorldWindow.getFloorContainer()
    sqWorld = p:getCurrentSquare()
    stackT.char, singleT.char = freeType(inv, STACK_TYPES), freeType(inv, SINGLE_TYPES)
    stackT.world = floor and freeType(floor, STACK_TYPES) or "Base.Apple"
    singleT.world = floor and freeType(floor, SINGLE_TYPES) or "Base.Saucepan"
    if not (stackT.char and singleT.char) then abort("every candidate type is already in the bag"); return end
    for _ = 1, 5 do local it = inv:AddItem(stackT.char); if it then given[#given + 1] = it end end
    local it1 = inv:AddItem(singleT.char); if it1 then given[#given + 1] = it1 end
    local function toGround(ft)
        local ok, it = pcall(function() return sqWorld:AddWorldInventoryItem(ft, 0.5, 0.5, 0) end)
        if ok and it then floorItems[#floorItems + 1] = it end
    end
    for _ = 1, 5 do toGround(stackT.world) end
    toGround(singleT.world)
    say("given: bag 5 x " .. stackT.char .. " + " .. singleT.char .. ", ground 5 x " .. stackT.world .. " + " .. singleT.world
        .. " (" .. #given .. " / " .. #floorItems .. ")")
end)
step(30, function()
    tabLoot()
    floor = ZeD_WorldWindow.getFloorContainer()
    local wc = contentOf("world")
    if floor and wc and wc._inventory ~= floor then
        oldWorldInv = wc._inventory
        say("the World window showed another container; the ground selected: " .. tostring(ZeD_WorldWindow.selectContainer(floor)))
    end
    say("extra columns: char " .. #(cwin()._mcSelected or {}) .. " world " .. #(wwin()._mcSelected or {}))
    for _, k in ipairs({ "char", "world" }) do
        local c = contentOf(k)
        if c then keep[k] = { sortCol = c._sortCol, sortAsc = c._sortAsc, pos = c._scroll and c._scroll.scrollPos or 0 } end
    end
    setView(false); sortName()
end)

-- one look: for the stack, then the single, in each window asked: scroll its
-- row / cell into view, read a few frames of drawing, check; a capture of the stack
local function look(tag, grid, mode, only, shotName)
    for _, which in ipairs({ "stack", "single" }) do
        step(4, function()
            for _, k in ipairs({ "char", "world" }) do
                if not only or only == k then reveal(k, (which == "stack") and stackT[k] or singleT[k]) end
            end
        end)
        step(12, function() capStart() end)
        step(6, function()
            capOn = false
            for _, k in ipairs({ "char", "world" }) do if not only or only == k then checkOne(k, tag, grid, mode, which) end end
            if which == "stack" then shot(shotName) end
        end)
    end
end

-- the list, Small
step(20, function() end)
look("small list", false, "wide", nil, "small_list")
-- the stack opened in both lists
step(4, function()
    for _, k in ipairs({ "char", "world" }) do openStack(k, true) end
end)
step(4, function()
    for _, k in ipairs({ "char", "world" }) do reveal(k, stackT[k]) end
end)
step(12, function() capStart() end)
step(6, function()
    capOn = false
    for _, k in ipairs({ "char", "world" }) do checkOpen(k, "open stack") end
    shot("open_stack")
end)
step(4, function()
    for _, k in ipairs({ "char", "world" }) do openStack(k, false) end
end)
-- the list, the WT column dragged down to the unit's width (as the divider drag sets it)
step(4, function()
    local cw = contentOf("char")._colWidths
    if cw and cw.wtU then oldWt = cw.wt; cw.wt = cw.wtU; say("char WT column " .. tostring(oldWt) .. " -> " .. cw.wtU) else fail("no wtU on the char list's widths") end
end)
look("narrow WT", false, "narrow", "char", "narrow_wt")
step(4, function() local cw = contentOf("char")._colWidths; if cw and oldWt then cw.wt = oldWt end end)
-- the grid, Small
step(4, function() setView(true) end)
step(20, function() end)
look("small grid", true, "wide", nil, "small_grid")
-- Large: the list, then the grid
step(4, function() setView(false); ZeD.applyTheme(nil, nil, "large") end)
step(40, function() tabLoot(); sortName() end)
look("large list", false, "wide", nil, "large_list")
step(4, function() setView(true) end)
step(20, function() end)
look("large grid", true, "fit", nil, "large_grid")
step(4, function() setView(false); ZeD.applyTheme(nil, nil, orig) end)
-- two columns: the bag beside a worn pack (both narrow; the bracket shows where it fits)
step(40, function()
    tabLoot(); sortName()
    local inv = p:getInventory()
    pack = inv:AddItem("Base.Bag_ALICEpack")
    if not pack then fail("no pack"); return end
    given[#given + 1] = pack
    local loc
    pcall(function() local ce = pack:canBeEquipped(); if ce and ce ~= "" then loc = ce else loc = pack:getBodyLocation() end end)
    pcall(function() p:setWornItem(loc, pack) end)
end)
step(30, function()
    local w = cwin()
    if pack and not colOn(w, pack:getInventory()) then say("pack column on: " .. tostring(ZeD_CharacterWindow.toggleColumn(pack:getInventory()))) end
end)
step(40, function()
    sortName()
    local n = #(contentOf("char")._colStates or {})
    say("char columns " .. n)
    if n < 2 then fail("the pack's column did not open beside the bag") end
end)
look("two columns", false, "fit", "char", "two_columns")
step(4, function() ZeD.applyTheme(nil, nil, "large") end)
step(40, function() tabLoot(); sortName() end)
look("two columns large", false, "fit", "char", "two_columns_large")
step(4, function() ZeD.applyTheme(nil, nil, orig) end)

-- put everything back
step(30, function()
    capOn = false
    unhook()
    if pack and colOn(cwin(), pack:getInventory()) then ZeD_CharacterWindow.toggleColumn(pack:getInventory()) end
    if oldWorldInv then ZeD_WorldWindow.selectContainer(oldWorldInv) end
    local st = gridStore()
    for key in pairs(gridTouched) do if gridOld[key] == NIL then st[key] = nil else st[key] = gridOld[key] end end
end)
step(20, function()
    for _, it in ipairs(floorItems) do
        pcall(function()
            local wo = it:getWorldItem()
            if wo then
                local sq = wo:getSquare()
                if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
                wo:removeFromWorld()
                wo:removeFromSquare()
            end
        end)
    end
    if pack then pcall(function() p:removeWornItem(pack) end) end
    for _, it in ipairs(given) do pcall(function() local ct = it:getContainer(); if ct then ct:Remove(it) end end) end
end)
step(30, function()
    for k, v in pairs(keep) do
        local c = contentOf(k)
        if c then
            c._sortCol, c._sortAsc = v.sortCol, v.sortAsc
            for _, cs in ipairs(c._colStates or {}) do
                cs.sortCol, cs.sortAsc = v.sortCol, v.sortAsc
                if cs.scroll then cs.scroll:setScrollPos(v.pos) end
            end
            if c._scroll then c._scroll:setScrollPos(v.pos) end
        end
    end
    if openedPair and ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    say("size back to " .. tostring(ZeD.currentSize) .. " | bag " .. stackT.char .. " left " .. held(p:getInventory(), stackT.char))
    say((fails == 0 and "all checks held" or (fails .. " checks FAILED")) .. "; DONE" .. (dead and " (aborted)" or ""))
end)

local function t()
    local s = steps[si]
    if not s then Events.OnTick.Remove(t); return end
    wait = wait + 1
    if wait >= s[1] then
        local ok, e = pcall(s[2])
        if not ok then say("ERR step " .. si .. " " .. tostring(e)) end
        si, wait = si + 1, 0
    end
end
Events.OnTick.Add(t)
say("start")
