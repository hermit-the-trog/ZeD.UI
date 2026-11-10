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
-- put everything back (the crate too)
at(1030, function()
    closeMenus()
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
    if tick > 1040 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
