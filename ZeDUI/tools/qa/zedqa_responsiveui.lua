-- ZeDUI/tools/qa/zedqa_responsiveui.lua  (Nov 9 2026, QA): ZeD's right-click menu under Responsive Context Menus
-- (ResponsiveUI, Workshop 3783387236; the QA save's mods.txt must list it beside ZeD_UI). The mod rebuilds an open
-- menu as things change; ZeD's menu must take the new options in place: the same menu, same place, same selection,
-- no close and open. Keep the mouse off the menu while it runs (a hovered cell takes the selection).
--   READ   a book's menu opened at night: Read greyed; day comes: Read live, in the same strip, still selected
--   KEEP   a keep-open row (added here, option.responsiveUIKeepOpen = true): the strip stays open after the pick and
--          its label counts the press; in the list, the same row in a submenu keeps the submenu open
--   PUTIN  the player walks from 6 tiles off a container to beside it: Put in Container appears in the open menu
--          (needs a container near the QA site; SKIP when none). The game's loot pane is what the option reads:
--          its inventory is reported too.
-- Pictures zqa_rui_*.png. The style, the time, the place and the book are put back. grep "ZEDQA rui".
local function say(s) print("ZEDQA rui " .. tostring(s)) end
local p = getPlayer()
local opt = ZeD.Settings.contextStyleOption
local was = { style = opt:getValue(), tod = getGameTime():getTimeOfDay(), x = p:getX(), y = p:getY(), z = p:getZ() }
local book, crate
local presses = 0
local steps, tick = {}, 0
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
local held

-- the keep-open rows: one at the top level, one in a submenu
local function addKeep(playerNum, context, items)
    local o = context:addOption(keepName(), nil, function() presses = presses + 1 end)
    o.responsiveUIKeepOpen = true
    local s = context:addOption("ZEDQA keep submenu")
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(s, sub)
    local so = sub:addOption(keepName() .. " sub", nil, function() presses = presses + 1 end)
    so.responsiveUIKeepOpen = true
end

local function report(tag)
    local v, z = menu()
    local items = z and z._ctx and (z._ctx.items or z._ctx.actions)
    local ri, rd = defStarting(items, READ)
    local sel = z and z._ctx and z._ctx.selected and items and items[z._ctx.selected]
    say(string.format("%s: ZeD menu %s same %s open %s at %s,%s | Read %s greyed %s | selected %s | Put in %s | keep %s",
        tag, tostring(z and z.Type), tostring(z ~= nil and z == held), tostring(z and z._ctx.open),
        tostring(z and z:getX()), tostring(z and z:getY()), tostring(ri), tostring(rd and rd.disabled()),
        tostring(sel and sel.name), tostring(hasPut(items)), tostring(defStarting(items, "ZEDQA keep-open") ~= nil)))
    local loot = getPlayerLoot(0)
    say(string.format("%s: dark %s, loot pane %s, the mod watching %s", tag, tostring(p:tooDarkToRead()),
        tostring(loot and loot.inventory and loot.inventory:getType()),
        tostring(ResponsiveUI and ResponsiveUI.controller and ResponsiveUI.controller:getSession(0) ~= nil)))
end

at(2, function()
    say("ResponsiveUI loaded " .. tostring(ResponsiveUI ~= nil and ResponsiveUI.controller ~= nil)
        .. ", ZeD support " .. tostring(ZeD.ModSupport and ZeD.ModSupport.ResponsiveUI ~= nil))
    if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    book = p:getInventory():AddItem("Base.Book")
    Events.OnFillInventoryObjectContextMenu.Add(addKeep)
    opt:setValue(1)
    -- the nearest container on this floor, within 15 tiles
    local cell, px, py, pz = getCell(), math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    local best
    for dx = -15, 15 do
        for dy = -15, 15 do
            local sq = cell:getGridSquare(px + dx, py + dy, pz)
            local objs = sq and sq:getObjects()
            for i = 0, (objs and objs:size() or 0) - 1 do
                local o = objs:get(i)
                if o and o:getContainer() and (not best or math.abs(dx) + math.abs(dy) < best.d) then
                    best = { sq = sq, d = math.abs(dx) + math.abs(dy) }
                end
            end
        end
    end
    crate = best and best.sq
    say("container " .. (crate and (crate:getX() .. "," .. crate:getY()) or "none: PUTIN SKIP"))
    if crate then goTo(crate:getX() + 6.5, crate:getY() + 0.5, crate:getZ()) end
    getGameTime():setTimeOfDay(23.5)
end)
-- READ
at(90, function() ISInventoryPaneContextMenu.createMenu(0, true, { book }, 700, 500) end)
at(110, function()
    local _, z = menu()
    held = z
    local items = z and z._ctx.items
    local ri = defStarting(items, READ)
    if ri then z._ctx.selected = ri end
    report("READ night")
    shot("read_night")
end)
at(120, function() getGameTime():setTimeOfDay(11.0) end)
at(300, function() report("READ day"); shot("read_day") end)
-- KEEP (strip)
at(310, function()
    local _, z = menu()
    local i = z and defStarting(z._ctx.items, "ZEDQA keep-open")
    if i then z._ctx.selected = i; z:confirm() else say("KEEP no keep-open row in the strip") end
end)
at(330, function() report("KEEP strip after the pick (expect keep-open (1), same, open)"); shot("keep_strip") end)
-- PUTIN
at(340, function() if crate then goTo(crate:getX() + 1.5, crate:getY() + 0.5, crate:getZ()) end end)
at(520, function() report("PUTIN beside the container"); shot("putin") end)
-- KEEP (list, in a submenu)
at(530, function()
    local v = getPlayerContextMenu(0); if v then v:hideAndChildren() end
    local _, z = menu(); if z and z._ctx.open then z:close() end
    opt:setValue(2)
end)
at(550, function() ISInventoryPaneContextMenu.createMenu(0, true, { book }, 700, 500) end)
at(570, function()
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
at(600, function()
    local _, z = menu()
    local sub = z and z._levels and z._levels[2]
    local r = sub and sub.sel and sub.rows[sub.sel]
    say(string.format("KEEP list after the pick (expect same, open, 2 levels, (2) sub): same %s open %s levels %s row %s",
        tostring(z == held), tostring(z and z._ctx.open), tostring(z and z._levels and #z._levels), tostring(r and r.def and r.def.name)))
    shot("keep_list")
end)
at(620, function()
    local v = getPlayerContextMenu(0); if v then v:hideAndChildren() end
    local _, z = menu(); if z and z._ctx.open then z:close() end
    Events.OnFillInventoryObjectContextMenu.Remove(addKeep)
    opt:setValue(was.style)
    getGameTime():setTimeOfDay(was.tod)
    goTo(was.x, was.y, was.z)
    if book and book:getContainer() then book:getContainer():Remove(book) end
    say("put back: style " .. tostring(was.style) .. ", time, place, book")
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
    if tick > 625 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
