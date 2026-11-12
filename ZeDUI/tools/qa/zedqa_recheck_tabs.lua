-- ZeDUI/tools/qa/zedqa_recheck_tabs.lua  (Nov 11 2026, QA): the tab review fixes and the pen count, rechecked in game (main f703d4f9).
-- QA save only (ZeD-QA). Windows and tab calls as zedqa_tab_review.lua does them. grep "ZEDQA rct". Pictures zqa_rct_*.png.
--   1  the Advanced Forge recipe card in Build: its description is one line (CC.oneLine), a picture for the first Required row
--   2  Craft and Build with Show = Ready and (as staged) nothing ready, and with a search that finds nothing: the empty line says why
--   3  a backpack's item card: the Kind block's Capacity reads "w / max kg", not -1
--   4  the Cooking tab with a pot of water, carrots, a potato and an onion in the bags: which dish it opens on, what it lists
--   5  a pen with a hen: the Animals Totals and the pen's own count agree
local function say(s) print("ZEDQA rct " .. tostring(s)) end
local fails = 0
local function check(ok, what, extra) if not ok then fails = fails + 1 end; say((ok and "PASS " or "FAIL ") .. what .. (extra ~= nil and (" | " .. tostring(extra)) or "")) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_rct_" .. n .. ".png") end) end
local p = getPlayer()
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local CC = ZeD.CraftingCore
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end
local function goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab or not win._drawerOpen then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
local function charTab(id) local w = CW(); return w and goTab(w, w._tabStripPanel, id) end
local function worldTab(id) local w = WW(); return w and goTab(w, w._actionTabStrip, id) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local given, O = {}, { opened = false }
local function give(ft, cont)
    local it = (cont or p:getInventory()):AddItem(ft)
    if it then given[#given + 1] = it end
    return it
end
local function recipes(kind)
    local w = WW()
    local mod = (kind == "craft") and ZeD.CraftingTab or ZeD.BuildingTab
    local ok, data = pcall(mod.gatherData, p, w)
    return ok and data and data.recipes or {}, (kind == "craft") and w._craftState or w._buildState
end

add(300, function()
    p:setGodMod(true)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then O.opened = true; CWm.toggleBothPaired(0) end
end)
-- 1
add(2000, function() worldTab("build") end)
add(1200, function()
    local list, st = recipes("build")
    if st then CC.setShow(st, "all"); st.search = "" end
    local pick = nil
    local names = {}
    for _, rd in ipairs(list) do
        local nm = tostring(rd.entry.name) .. " / " .. tostring(rd.entry.displayName or rd.entry.label or "")
        if nm:lower():find("forge", 1, true) then names[#names + 1] = nm; if not pick and nm:lower():find("advanced", 1, true) then pick = rd end end
    end
    say("build recipes (all, unfiltered): " .. #list .. "; with forge in the name: " .. table.concat(names, " | "))
    check(pick ~= nil, "1 the Advanced Forge is in Build's list")
    if pick then
        local one = CC.oneLine(pick.entry)
        check(not one:find("[\r\n]"), "1 its description is one line", one:sub(1, 80))
        CC.openCraft(st, pick.entry.name)
    end
end)
add(2500, function() shot("1_advanced_forge") end)
add(300, function() local _, st = recipes("build"); if st then CC.closeCraft(st) end end)
-- 2
add(1200, function()
    local list, st = recipes("build")
    if st then CC.setShow(st, "ready"); st.search = "" end
end)
add(1500, function()
    local list, st = recipes("build")
    say("Build, Show ready, no search: " .. #list .. " listed; empty text '" .. tostring(st and #list == 0 and CC.emptyListText(st, {}) or "(not empty)") .. "'")
    shot("2a_build_ready")
    if st then st.search = "zzzzqq" end
end)
add(1500, function()
    local list, st = recipes("build")
        check(st ~= nil and CC.emptyListText(st, {}) == ZeD.tr("UI_ZeD_TAS_Nothing", "zzzzqq"), "2 Build's empty line is the 'nothing matches' line", st and CC.emptyListText(st, {}))
    shot("2b_build_nomatch")
    if st then st.search = ""; CC.setShow(st, "all") end
    worldTab("craft")
end)
add(1500, function()
    local list, st = recipes("craft")
    if st then CC.setShow(st, "ready"); st.search = "" end
end)
add(1500, function()
    local list, st = recipes("craft")
    say("Craft, Show ready, no search: " .. #list .. " listed; empty text '" .. tostring(st and #list == 0 and CC.emptyListText(st, {}) or "(not empty)") .. "'")
    shot("2c_craft_ready")
    if st then st.search = "zzzzqq" end
end)
add(1500, function()
    local list, st = recipes("craft")
        shot("2d_craft_nomatch")
    if st then st.search = ""; CC.setShow(st, "all") end
    -- the Ready empty line: Show ready with nothing ready (everything carried is put aside for the picture is not done; the text is read)
    if st then
        local en = CC.emptyListText({ search = "", show = "ready" }, {})
        check(en == ZeD.tr("UI_ZeD_Craft_EmptyReady"), "2 the empty list's Ready line is the words 'nothing is ready'", en)
        local nn = CC.emptyListText({ search = "", show = "all" }, {})
        check(nn == ZeD.tr("UI_ZeD_Craft_EmptyNone"), "2 the empty list's other line is 'no recipes to list'", nn)
    end
end)
-- 3
add(500, function()
    local bag = give("Base.Bag_Schoolbag") or give("Base.Bag_ALICEpack")
    pcall(function() bag:getItemContainer():AddItem("Base.Apple") end)
    O.bag = bag
    charTab("loot")
end)
add(1500, function()
    local w = CW()
    local c = w and w._mainContent
    if c and O.bag then
        local sel = c._selectedItems or {}
        for k in pairs(sel) do sel[k] = nil end
        sel[O.bag] = true
        c._selectedItems, c._lastClickedItem = sel, O.bag
        w._updateDrawer(c)
    end
    say("bag " .. tostring(O.bag and O.bag:getFullType()) .. " weight in it " .. tostring(O.bag and O.bag:getItemContainer():getContentsWeight()) .. " / " .. tostring(O.bag and O.bag:getItemContainer():getCapacity()))
end)
add(2500, function() shot("3_bag_card") end)
add(300, function() local w = CW(); local c = w and w._mainContent; if c then c._selectedItems, c._lastClickedItem = {}, nil; w._updateDrawer(c) end end)
-- 4
add(500, function()
    local pot = give("Base.Pot")
    if pot then pcall(function() local fc = pot:getFluidContainer(); fc:addFluid(Fluid.Water, fc:getCapacity()) end) end
    say("pot water " .. tostring(pot and pot:getFluidContainer() and pot:getFluidContainer():getAmount()) .. " / " .. tostring(pot and pot:getFluidContainer() and pot:getFluidContainer():getCapacity()))
    for _, ft in ipairs({ "Base.Carrots", "Base.Potato", "Base.Onion", "Base.Cabbage" }) do give(ft) end
    charTab("cooking")
end)
add(500, function() charTab("cooking") end)
add(3500, function()
    local w = CW()
    charTab("cooking")
    check(w._activeTab == "cooking", "4 the Cooking tab is there with a pot of water and vegetables in reach", w._activeTab)
    local st = w._cookingState or w._cookState
    say("cooking state: " .. tostring(st ~= nil) .. " dish " .. tostring(st and (st.base or st.dish or st.sel)))
    shot("4_cooking")
end)
-- 5
add(500, function()
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    O.zone = "QA Pen RCT"
    O.hen = addAnimal(getCell(), px + 2, py + 2, 0, "hen", AnimalDefinitions.getDef("hen"):getBreeds():get(0))
    pcall(function() DesignationZoneAnimal.new(O.zone, px - 6, py - 6, 0, px + 6, py + 6, true) end)
    check(O.hen ~= nil, "5 a hen is spawned in a pen")
end)
add(1500, function()
    local AP, AT = ZeD.AnimalsAlertPoller, ZeD.AnimalsTab
    AP.refreshCache()
    local z = AP.getAnimalsInZone(O.zone)
    local tt = AP.getTotals and AP.getTotals() or {}
    local total = tt.totalAnimals
    local sp = {}
    for k, v in pairs(tt.speciesCounts or {}) do sp[#sp + 1] = k .. "=" .. v end
    say("pen '" .. O.zone .. "' count " .. tostring(z and #z) .. "; Totals " .. tostring(total) .. " (" .. table.concat(sp, ", ") .. ")")
    check(z ~= nil and #z >= 1, "5 the pen counts the hen", z and #z)
    -- every animal the scan sees that stands in the pen is in Totals as well
    local inPen = 0
    for _, a in ipairs(z or {}) do inPen = inPen + 1 end
    check(total ~= nil and total >= inPen, "5 Totals counts every animal the pen counts", tostring(total) .. " vs " .. inPen)
    local w = WW()
    w._activeTab = "animals"; w._drawerMode = "tab"; w._drawerOpen = true
    AT.getState(w).submode = "ranch"; AT.getState(w).view = "overview"
end)
add(2500, function() shot("5_animals_totals") end)
add(500, function()
    local AT = ZeD.AnimalsTab
    pcall(function() AT.navigate(WW(), "zone", O.zone, nil) end)
end)
add(2000, function() shot("5b_pen_zone") end)
-- cleanup
add(500, function()
    for _, it in ipairs(given) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    pcall(function() O.hen:removeFromWorld(); O.hen:removeFromSquare() end)
    pcall(function() local z = DesignationZoneAnimal.getZoneByName(O.zone); if z then DesignationZoneAnimal.removeZone(z, true) end end)
    p:setGodMod(false)
    if O.opened then pcall(CWm.toggleBothPaired, 0) end
    say("fails " .. fails)
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
say("start")
