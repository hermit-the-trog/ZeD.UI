-- ZeDUI/tools/qa/zedqa_responsiveui.lua  (Nov 9 2026, QA): ZeD's right-click menu under Responsive Context Menus
-- (ResponsiveUI, Workshop 3783387236; the QA save's mods.txt must list it beside ZeD_UI). The mod rebuilds an open
-- menu every 250 ms as things change; ZeD's menu must take the new options in place: the same menu, same place,
-- same selection, no close and open. Keep the mouse off the menu while it runs (a hovered cell takes the selection).
--   LIVE   the proof the script controls: a test option "ZEDQA live" (added through OnFillInventoryObjectContextMenu)
--          whose notAvailable and tool tip follow a flag. Menu opened with the flag ON (greyed), the row selected, the
--          flag flipped OFF: within ~1.7 s the SAME menu is open at the same place, the row is live, still selected;
--          flipped ON again: greyed again. Once in the Strip, once in the List.
--   READ   best effort: night plus an unlit indoor spot, a book's menu: Read greyed; then day: Read live. When the
--          spot never gets dark (lights) it is INFO, not FAIL: LIVE carries the proof.
--   KEEP   a keep-open row (option.responsiveUIKeepOpen = true): the strip stays open after the pick and its label
--          counts the press; in the list, the same row in a submenu keeps the submenu open
--   PUTIN  a crate is built 6 tiles off the player; the menu is opened, the player steps beside the crate: Put in
--          Container appears in the same open menu. The crate is removed at the end (and old ones swept at the start).
--   ESC    the mod's Escape key path on a keep-open submenu (List, then Strip), after one keep-open press: ZeD's menu must
--          close; open and stale is FAIL, open but still refreshing is INFO
--   TICK   the Lists pop-up's tick boxes (keepOpen rows): a temporary loadout "ZEDQA tick" is ticked and unticked; the
--          same pop-up stays open and the tick flips each press. The pop-up is List look only (the Strip has no tick rows)
-- Pictures zqa_rui_*.png. The style, the time, the place and the book are put back. grep "ZEDQA rui".
local function say(s) print("ZEDQA rui " .. tostring(s)) end
local p = getPlayer()
local opt = ZeD.Settings.contextStyleOption
local was = { style = opt:getValue(), tod = getGameTime():getTimeOfDay(), x = p:getX(), y = p:getY(), z = p:getZ() }
local book, crateObj, crateSq, crateDir
local presses = 0
local liveOn = true
local nPass, nFail = 0, 0
local steps, tick = {}, 0
local function check(ok, what)
    if ok then nPass = nPass + 1; say("PASS " .. what) else nFail = nFail + 1; say("FAIL " .. what) end
end
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function goTo(x, y, z) p:setX(x); p:setY(y); p:setZ(z); p:setLastX(x); p:setLastY(y); p:setLastZ(z) end
local function menu() local v = getPlayerContextMenu(0); return v, v and v._zedMenu end
local function shot(name) pcall(function() getCore():TakeFullScreenshot("zqa_rui_" .. name .. ".png") end) end
local READ = getText("ContextMenu_Read")
local PUT1, PUT2 = getText("ContextMenu_Put_in_Container"), getText("ContextMenu_PutInContainer", "")
local function defStarting(list, text)
    for i, d in ipairs(list or {}) do
        if type(d.name) == "string" and text ~= "" and d.name:sub(1, #text) == text then return i, d end
    end
end
local function hasPut(list) return defStarting(list, PUT1) ~= nil or defStarting(list, PUT2) ~= nil end
local function keepName() return "ZEDQA keep-open (" .. presses .. ")" end
local function greyed(d)
    if not d then return nil end
    local v = d.disabled
    if type(v) == "function" then local ok, r = pcall(v); v = ok and r end
    return v == true
end
local held

-- the test rows: the keep-open ones (one at the top level, one in a submenu) and the flag-driven one
local function addKeep(playerNum, context, items)
    local o = context:addOption(keepName(), nil, function() presses = presses + 1 end)
    o.responsiveUIKeepOpen = true
    local s = context:addOption("ZEDQA keep submenu")
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(s, sub)
    local so = sub:addOption(keepName() .. " sub", nil, function() presses = presses + 1 end)
    so.responsiveUIKeepOpen = true
    local lv = context:addOption("ZEDQA live", nil, function() end)
    lv.notAvailable = liveOn
    local tip = ISToolTip:new()
    tip:initialise(); tip:setVisible(false)
    tip.description = liveOn and "ZEDQA live: blocked by the flag" or "ZEDQA live: ready"
    lv.toolTip = tip
end

local function closeMenus()
    local v = getPlayerContextMenu(0); if v then v:hideAndChildren() end
    local _, z = menu(); if z and z._ctx and z._ctx.open then z:close() end
end

-- ESC in a keep-open submenu: the mod's own key handler (ResponsiveUI.onStickyKeyStartPressed, Client.lua) when it is
-- reachable; else what it does (close the game's menu for player 0, forget the session)
local escRun = {}
local function pressEscape()
    local v = getPlayerContextMenu(0)
    local h = ResponsiveUI and ResponsiveUI.onStickyKeyStartPressed
    say(string.format("ESC: game menu visible %s, mod handler reachable %s, Main Menu key is ESC %s",
        tostring(v and v:getIsVisible()), tostring(type(h) == "function"),
        tostring(pcall(function() return getCore():isKey("Main Menu", Keyboard.KEY_ESCAPE) end))))
    if type(h) == "function" then
        local ok, e = pcall(h, Keyboard.KEY_ESCAPE)
        say("ESC: the mod's handler ran " .. tostring(ok) .. (ok and "" or (" " .. tostring(e))))
    else
        if v then
            if type(v.closeAll) == "function" then v:closeAll() else v:hideAndChildren() end
        end
        if ResponsiveUI and ResponsiveUI.controller then pcall(function() ResponsiveUI.controller:forget(0) end) end
        say("ESC: no handler reachable; closed the game's menu by hand")
    end
end
-- the keep-open pick inside the submenu, Strip: step 1 goes into the submenu, step 2 presses its keep-open row
local function stripIntoSub()
    local _, z = menu()
    held = z
    local i = z and defStarting(z._ctx.items, "ZEDQA keep submenu")
    if i then z._ctx.selected = i; z:confirm() else say("ESC strip: no keep submenu row") end
end
local function stripPressSub()
    local _, z = menu()
    local items = z and z:_currentItems()
    local i
    for ri, d in ipairs(items or {}) do if tostring(d.name):find("ZEDQA keep%-open") then i = ri end end
    if i then z._ctx.selected = i; z:confirm() else say("ESC strip: no keep-open row in the submenu") end
end
local function listPressSub()
    local _, z = menu()
    held = z
    local top = z and z._levels and z._levels[1]
    if not top then say("ESC list: no list"); return end
    for ri, r in ipairs(top.rows) do if r.def and r.def.name == "ZEDQA keep submenu" then top.sel = ri end end
    z:_openSub(1, true)
    local sub = z._levels[2]
    if not sub then say("ESC list: the submenu did not open"); return end
    for ri, r in ipairs(sub.rows) do if r.def and tostring(r.def.name):find("ZEDQA keep%-open") then sub.sel = ri end end
    z:confirm()
end
-- fire ESC once the menu is proven open after the keep-open pick; the flag flips so a stale menu shows
local function escFire(name)
    local _, z = menu()
    local sub = z and ((z._levels and #z._levels == 2) or (z._ctx and #z._ctx.path == 1))
    escRun.z, escRun.p0 = z, presses
    check(z ~= nil and z._ctx.open == true and sub == true, "ESC " .. name .. ": the keep-open pick left the menu open in its submenu")
    liveOn = false
    pressEscape()
end
-- 30 ticks later: closed is a PASS; open is FAIL when stale (no refresh follows), INFO when it still refreshes
local function escCheck(name)
    local _, z = menu()
    local open = z ~= nil and z._ctx ~= nil and z._ctx.open == true
    local ours = escRun.z ~= nil and escRun.z._ctx ~= nil and escRun.z._ctx.open == true
    escRun.open = open or ours
    say(string.format("ESC %s: ZeD menu open %s (the one held %s), game menu visible %s", name, tostring(open), tostring(ours),
        tostring(getPlayerContextMenu(0) and getPlayerContextMenu(0):getIsVisible())))
    if not escRun.open then check(true, "ESC " .. name .. ": ZeD's menu closed on Escape") end
    shot("esc_" .. name)
end
-- ~100 ticks after that (the mod refreshes every ~15 ticks): an open menu must have taken the flag flip
local function escStale(name)
    if not escRun.open then closeMenus(); return end
    local _, cur = menu()
    local z, d = (cur and cur._ctx and cur._ctx.open) and cur or escRun.z, nil
    if z and z._ctx and z._ctx.open then
        local _, nd = defStarting(z._ctx.actions, "ZEDQA live")   -- (both menus replace actions on a refresh)
        d = nd
    end
    local live = d ~= nil and greyed(d) == false
    if live then say("INFO ESC " .. name .. ": ZeD's menu stayed open after Escape but it still refreshes (live)")
    else check(false, "ESC " .. name .. ": ZeD's menu stayed open after Escape and is stale (no refresh)") end
    closeMenus()
end

local function report(tag)
    local v, z = menu()
    local items = z and z._ctx and (z._ctx.items or z._ctx.actions)
    local ri, rd = defStarting(items, READ)
    local sel = z and z._ctx and z._ctx.selected and items and items[z._ctx.selected]
    say(string.format("%s: ZeD menu %s same %s open %s at %s,%s | Read %s greyed %s | selected %s | Put in %s | keep %s",
        tag, tostring(z and z.Type), tostring(z ~= nil and z == held), tostring(z and z._ctx.open),
        tostring(z and z:getX()), tostring(z and z:getY()), tostring(ri), tostring(greyed(rd)),
        tostring(sel and sel.name), tostring(hasPut(items)), tostring(defStarting(items, "ZEDQA keep-open") ~= nil)))
    local loot = getPlayerLoot(0)
    say(string.format("%s: dark %s, loot pane %s, the mod watching %s", tag, tostring(p:tooDarkToRead()),
        tostring(loot and loot.inventory and loot.inventory:getType()),
        tostring(ResponsiveUI and ResponsiveUI.controller and ResponsiveUI.controller:getSession(0) ~= nil)))
end

-- ------------------------------------------------------------ the live row
-- the open menu's "ZEDQA live" row: menu, row index, def, the selected row index (Strip or List)
local function liveState()
    local _, z = menu()
    if not z then return nil end
    if opt:getValue() == 2 then
        local top = z._levels and z._levels[1]
        for ri, r in ipairs(top and top.rows or {}) do
            if r.def and tostring(r.def.name):sub(1, 10) == "ZEDQA live" then return z, ri, r.def, top.sel end
        end
        return z, nil, nil, top and top.sel
    end
    local items = z._ctx and z._ctx.items
    local i, d = defStarting(items, "ZEDQA live")
    return z, i, d, z._ctx and z._ctx.selected
end
local function liveSelect(z, ri)
    if opt:getValue() == 2 then
        local top = z._levels and z._levels[1]
        if top then top.sel = ri end
    else
        z._ctx.selected = ri
    end
end
local liveRun = {}
local function liveOpen(style)
    closeMenus()
    liveOn = true
    opt:setValue(style)
    liveRun = {}
    ISInventoryPaneContextMenu.createMenu(0, true, { book }, 700, 500)
end
local function liveFirst(name)
    local z, ri, d = liveState()
    held = z
    liveRun.z = z
    liveRun.x, liveRun.y = z and z:getX(), z and z:getY()
    check(z ~= nil and ri ~= nil, "LIVE " .. name .. ": the menu is open with the ZEDQA live row")
    if z and ri then liveSelect(z, ri) end
    liveRun.g1 = greyed(d)
    check(liveRun.g1 == true, "LIVE " .. name .. ": the row is greyed with the flag ON")
    shot("live_" .. name .. "_on")
end
local function liveOff(name)
    local z, ri, d, sel = liveState()
    liveRun.g2 = greyed(d)
    liveRun.same2 = z ~= nil and z == liveRun.z and z._ctx ~= nil and z._ctx.open == true
    liveRun.pos2 = z ~= nil and z:getX() == liveRun.x and z:getY() == liveRun.y
    liveRun.sel2 = ri ~= nil and sel == ri
    check(liveRun.g2 == false, "LIVE " .. name .. ": the row is live after the flag went OFF")
    check(liveRun.same2, "LIVE " .. name .. ": the SAME ZeD menu is still open after the refresh")
    check(liveRun.pos2, "LIVE " .. name .. ": the menu stayed at the same position")
    check(liveRun.sel2, "LIVE " .. name .. ": the selection stayed on the row")
    shot("live_" .. name .. "_off")
end
local function liveBack(name)
    local z, ri, d, sel = liveState()
    local g3 = greyed(d)
    local same3 = z ~= nil and z == liveRun.z and z._ctx ~= nil and z._ctx.open == true
    local sel3 = ri ~= nil and sel == ri
    check(g3 == true, "LIVE " .. name .. ": the row is greyed again with the flag back ON")
    check(same3, "LIVE " .. name .. ": still the same menu after the second flip")
    check(sel3, "LIVE " .. name .. ": the selection is still on the row")
    say(string.format("LIVE %s: greyed %s -> %s -> %s, same menu %s, selected %s", name, tostring(liveRun.g1),
        tostring(liveRun.g2), tostring(g3), tostring(liveRun.same2 and same3), tostring(liveRun.sel2 and sel3)))
    shot("live_" .. name .. "_back")
    closeMenus()
end

-- ------------------------------------------------------------ the crate
local function findInfo(full)
    local infos = SpriteConfigManager.GetObjectInfoList()
    for i = 0, infos:size() - 1 do
        local info = infos:get(i)
        local parent = info:getScript() and info:getScript():getParent()
        if parent and tostring(parent:getScriptObjectFullType()) == full then return info end
    end
end
local function isTestCrate(o)
    if not (instanceof(o, "IsoThumpable") and tostring(o:getName()) == "Wood_Crate_Lvl1" and o:getContainer()) then return false end
    return o:getContainer():getItems():size() == 0 and not o:isLockedByPadlock() and (o:getLockedByCode() or 0) == 0
end
-- empty wooden crates within 8 tiles of the start spot (this script's own leftovers)
local function sweepCrates(label)
    local n = 0
    local bx, by, bz = math.floor(was.x), math.floor(was.y), math.floor(was.z)
    for dy = -8, 8 do for dx = -8, 8 do
        local sq = getCell():getGridSquare(bx + dx, by + dy, bz)
        local objs = sq and sq:getObjects()
        for i = (objs and objs:size() or 0) - 1, 0, -1 do
            local o = objs:get(i)
            if isTestCrate(o) then sq:transmitRemoveItemFromSquare(o); n = n + 1 end
        end
    end end
    say(label .. ": swept " .. n .. " test crate(s)")
end
local function squareHasContainer(sq)
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do if objs:get(i):getContainer() then return true end end
    return false
end
local function buildCrate()
    local info = findInfo("Base.Wood_Crate_Lvl1")
    if not info then say("INFO no crate recipe found: PUTIN SKIP"); return end
    local bx, by, bz = math.floor(was.x), math.floor(was.y), math.floor(was.z)
    for _, d in ipairs({ { 6, 0 }, { -6, 0 }, { 0, 6 }, { 0, -6 } }) do
        local sq = getCell():getGridSquare(bx + d[1], by + d[2], bz)
        if sq and not squareHasContainer(sq) then
            p:setBuildCheat(true)
            local b = ISBuildIsoEntity:new(p, info, 1, ISInventoryPaneContextMenu.getContainers(p))
            b.buildCheat = true; b.player = 0; b.sq = sq
            local ok, valid = pcall(function() return b:isValid(sq) end)
            if ok and valid then pcall(function() b:create(bx + d[1], by + d[2], bz, false, nil) end) end
            p:setBuildCheat(false)
            if ok and valid then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do
                    if isTestCrate(objs:get(i)) then crateObj, crateSq, crateDir = objs:get(i), sq, d; return end
                end
            end
        end
    end
    say("INFO no square took a crate 6 tiles off: PUTIN SKIP")
end
local function removeCrate()
    if crateObj and crateSq then
        pcall(function() crateObj:getContainer():removeAllItems(); crateSq:transmitRemoveItemFromSquare(crateObj) end)
        crateObj = nil
    end
end

-- the nearest roofed, free square within 12 tiles (the best chance of an unlit spot)
local function findIndoor()
    local bx, by, bz = math.floor(was.x), math.floor(was.y), math.floor(was.z)
    local best, bd
    for dy = -12, 12 do for dx = -12, 12 do
        local sq = getCell():getGridSquare(bx + dx, by + dy, bz)
        local okSq = sq and pcall(function() return sq:isOutside() end) and not sq:isOutside() and sq:isFree(false)
        if okSq and (not bd or math.abs(dx) + math.abs(dy) < bd) then best, bd = sq, math.abs(dx) + math.abs(dy) end
    end end
    return best
end

-- ------------------------------------------------------------ the steps
at(2, function()
    say("ResponsiveUI loaded " .. tostring(ResponsiveUI ~= nil and ResponsiveUI.controller ~= nil)
        .. ", ZeD support " .. tostring(ZeD.ModSupport and ZeD.ModSupport.ResponsiveUI ~= nil))
    if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    book = p:getInventory():AddItem("Base.Book")
    Events.OnFillInventoryObjectContextMenu.Add(addKeep)
    opt:setValue(1)
    sweepCrates("start")
    buildCrate()
    say("crate " .. (crateSq and (crateSq:getX() .. "," .. crateSq:getY()) or "none: PUTIN SKIP"))
end)

-- LIVE, Strip
at(10, function() liveOpen(1) end)
at(30, function() liveFirst("strip") end)
at(40, function() liveOn = false end)
at(140, function() liveOff("strip") end)
at(150, function() liveOn = true end)
at(250, function() liveBack("strip") end)
-- LIVE, List
at(260, function() liveOpen(2) end)
at(280, function() liveFirst("list") end)
at(290, function() liveOn = false end)
at(390, function() liveOff("list") end)
at(400, function() liveOn = true end)
at(500, function() liveBack("list") end)

-- READ (best effort: needs real darkness)
at(510, function()
    closeMenus()
    opt:setValue(1)
    getGameTime():setTimeOfDay(0)
    local sq = findIndoor()
    if sq then goTo(sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ()) end
    say("READ spot " .. (sq and (sq:getX() .. "," .. sq:getY()) or "none indoors") .. ", night set")
end)
at(540, function()
    local dark = p:tooDarkToRead()
    say("READ dark at night: " .. tostring(dark))
    if not dark then say("INFO READ: never dark here (lights)"); return end
    ISInventoryPaneContextMenu.createMenu(0, true, { book }, 700, 500)
end)
at(560, function()
    if not p:tooDarkToRead() then return end
    local _, z = menu()
    held = z
    local items = z and z._ctx.items
    local ri, rd = defStarting(items, READ)
    if ri then z._ctx.selected = ri end
    check(ri ~= nil and greyed(rd) == true, "READ night: Read is greyed")
    report("READ night")
    shot("read_night")
end)
at(570, function() getGameTime():setTimeOfDay(11.0) end)
at(700, function()
    local _, z = menu()
    if not z then say("INFO READ: no menu to check by day"); return end
    local items = z._ctx.items
    local ri, rd = defStarting(items, READ)
    if p:tooDarkToRead() then
        say("INFO READ: still dark by day here (lights); the day half is not shown")
    else
        check(greyed(rd) == false and z == held, "READ day: Read is live in the same menu")
    end
    report("READ day")
    shot("read_day")
    closeMenus()
    getGameTime():setTimeOfDay(was.tod)
end)

-- KEEP (strip)
at(720, function()
    goTo(was.x, was.y, was.z)
    opt:setValue(1)
    ISInventoryPaneContextMenu.createMenu(0, true, { book }, 700, 500)
end)
at(740, function()
    local _, z = menu()
    held = z
    local i = z and defStarting(z._ctx.items, "ZEDQA keep-open")
    if i then z._ctx.selected = i; z:confirm() else say("KEEP no keep-open row in the strip") end
end)
at(760, function()
    local _, z = menu()
    check(presses == 1 and z ~= nil and z == held and z._ctx.open == true, "KEEP strip: the pick counted once and the strip stayed open")
    report("KEEP strip after the pick (expect keep-open (1), same, open)")
    shot("keep_strip")
end)
-- PUTIN: the menu is still open; the player steps beside the crate
at(770, function()
    if not crateSq then say("INFO PUTIN SKIP (no crate)"); return end
    local _, z = menu()
    check(not hasPut(z and z._ctx.items), "PUTIN before: no Put in Container with the crate 6 tiles off")
    goTo(crateSq:getX() - crateDir[1] / 6 * 1.5 + 0.5, crateSq:getY() - crateDir[2] / 6 * 1.5 + 0.5, crateSq:getZ())
end)
at(930, function()
    if not crateSq then return end
    local _, z = menu()
    check(z ~= nil and z == held and hasPut(z._ctx.items), "PUTIN: Put in Container appeared in the same open menu")
    report("PUTIN beside the container")
    shot("putin")
end)
-- KEEP (list, in a submenu)
at(940, function()
    closeMenus()
    opt:setValue(2)
end)
at(960, function() ISInventoryPaneContextMenu.createMenu(0, true, { book }, 700, 500) end)
at(980, function()
    local _, z = menu()
    held = z
    local top = z and z._levels and z._levels[1]
    if not top then say("KEEP no list"); return end
    for ri, r in ipairs(top.rows) do if r.def and r.def.name == "ZEDQA keep submenu" then top.sel = ri end end
    z:_openSub(1, true)
    local sub = z._levels[2]
    say("KEEP list submenu open " .. tostring(sub ~= nil))
    if sub then
        for ri, r in ipairs(sub.rows) do if r.def and tostring(r.def.name):find("ZEDQA keep%-open") then sub.sel = ri end end
        z:confirm()
    end
end)
at(1010, function()
    local _, z = menu()
    local sub = z and z._levels and z._levels[2]
    local r = sub and sub.sel and sub.rows[sub.sel]
    check(z ~= nil and z == held and z._ctx.open == true and z._levels ~= nil and #z._levels == 2 and presses == 2,
        "KEEP list: the pick counted (2) and the submenu stayed open in the same menu")
    say(string.format("KEEP list after the pick (expect same, open, 2 levels, (2) sub): same %s open %s levels %s row %s",
        tostring(z == held), tostring(z and z._ctx.open), tostring(z and z._levels and #z._levels), tostring(r and r.def and r.def.name)))
    shot("keep_list")
end)
-- ESC in a keep-open submenu, List (the mod's Escape closes the game's menu; ZeD's must go with it)
at(1030, function() closeMenus(); liveOn = true; opt:setValue(2) end)
at(1050, function() ISInventoryPaneContextMenu.createMenu(0, true, { book }, 700, 500) end)
at(1070, listPressSub)
at(1100, function() escFire("list") end)
at(1130, function() escCheck("list") end)
at(1230, function() escStale("list") end)
-- ESC in a keep-open submenu, Strip
at(1250, function() closeMenus(); liveOn = true; escRun = {}; opt:setValue(1) end)
at(1270, function() ISInventoryPaneContextMenu.createMenu(0, true, { book }, 700, 500) end)
at(1290, stripIntoSub)
at(1310, stripPressSub)
at(1340, function() escFire("strip") end)
at(1370, function() escCheck("strip") end)
at(1470, function() escStale("strip") end)

-- THE LISTS TICK BOXES: the mark strip's Lists pop-up (ZeD.ListsUI.openPopup, only ever the List look: the Strip
-- has no tick-box rows). A temporary loadout is made; a keepOpen row is pressed twice through the menu's own confirm.
local tickRun = {}
local function tickRow(z)
    local top = z and z._levels and z._levels[1]
    for ri, r in ipairs(top and top.rows or {}) do
        if r.def and r.def.keepOpen and r.def.name == tickRun.name then return top, ri, r.def end
    end
end
local function tickPress()
    local z = tickRun.z
    local top, ri, def = tickRow(z)
    if not ri then say("TICK no row for the test list"); return end
    top.sel = ri
    z:confirm()
end
at(1490, function()
    closeMenus()
    liveOn = true
    local l = ZeD.Lists.create(p, "loadout", "ZEDQA tick")
    tickRun.list, tickRun.name = l, l and l.name
    local z = l and ZeD.ListsUI.openPopup(0, book, 700, 500)
    tickRun.z = z
    local _, ri, def = tickRow(z)
    if def then tickRun.before = def.check() end   -- (not "and ... or nil": that turns false into nil)
    check(z ~= nil and ri ~= nil and tickRun.before == false, "TICK: the Lists pop-up is open with the test list unticked")
    shot("tick_before")
end)
at(1520, tickPress)
at(1550, function()
    local z = tickRun.z
    local _, ri, def = tickRow(z)
    if def then tickRun.after = def.check() end
    check(z ~= nil and z._ctx.open == true and z == ZeD.ListsUI.popup and ri ~= nil, "TICK: the same pop-up is still open after the press")
    check(tickRun.after == true, "TICK: the row's tick flipped on")
    shot("tick_after")
end)
at(1570, tickPress)
at(1600, function()
    local z = tickRun.z
    local _, ri, def = tickRow(z)
    check(z ~= nil and z._ctx.open == true and def ~= nil and def.check() == false, "TICK: pressed again, still open and ticked back off")
    say(string.format("TICK check %s -> %s -> %s", tostring(tickRun.before), tostring(tickRun.after), tostring(def and def.check())))
    if z and z._ctx.open then z:close() end
    if tickRun.list then ZeD.Lists.delete(p, tickRun.list.id) end   -- the temporary loadout goes
    say("TICK test list removed")
end)

-- put everything back (the crate too)
at(1620, function()
    closeMenus()
    liveOn = true
    Events.OnFillInventoryObjectContextMenu.Remove(addKeep)
    opt:setValue(was.style)
    getGameTime():setTimeOfDay(was.tod)
    goTo(was.x, was.y, was.z)
    if book and book:getContainer() then book:getContainer():Remove(book) end
    removeCrate()
    sweepCrates("end")
    say("put back: style " .. tostring(was.style) .. ", time, place, book, crate")
    say("RESULT " .. nPass .. " pass, " .. nFail .. " fail")
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do
        if s.n == tick then
            local ok, e = pcall(s.fn)
            if not ok then say("ERR step " .. s.n .. ": " .. tostring(e)) end
        end
    end
    if tick > 1640 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
