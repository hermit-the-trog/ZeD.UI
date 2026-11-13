-- ZeDUI/tools/qa/zedqa_ctx_overlap.lua  (tag ctxov, Nov 8 2026): a right-click submenu that lies over its parent keeps
-- the pointer. The player's report on beta 8a: "If one context menu overlaps the previous one, then when I hover the
-- mouse over it, it immediately resets." In game on the ZeD-QA save, run it at 4K (fullscreen4k) and at 1280x800
-- (windowed -Width 1280 -Height 800); the screen size is read, not set.
--   LIST   the list style: the menu opens at the right screen edge on an apple (Eat has a submenu), the Eat submenu opens
--          to its left. Its natural overlap is a sliver, so the submenu is then slid to cover most of the parent, as a
--          small screen does. The pointer (the menus' getMouseX / getMouseY, the way zedqa_minsidebar.lua tells the belt
--          where it is) goes over each submenu row inside the parent's box: the submenu stays open, its row is the
--          selection, the parent stays on Eat; a press there runs the submenu's row, not the parent's.
--   STRIP  the strip style: the same menu, Eat drilled into; the pointer over each cell keeps the drill-down and
--          selects the cell under it. (The strip draws its submenus in place of the strip, so nothing overlaps: this
--          is the check that hovering after a drill does not pop back.)
--   PUT BACK  the style option, the apple, the real cursor.
-- grep "ZEDQA ctxov"; shots zqa_ctxov_*.png.
local function say(s) print("ZEDQA ctxov " .. tostring(s)) end
local p = getPlayer()
local fails = 0
local function check(ok, what)
    if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ctxov_" .. n .. ".png") end) end
local opt = ZeD.Settings and ZeD.Settings.contextStyleOption
if not (p and opt and ZeD_ContextList and ZeD_ContextMenu) then say("ERR ZeD's context menus are not loaded"); say("DONE"); return end

local SW, SH = getCore():getScreenWidth(), getCore():getScreenHeight()
say("screen " .. SW .. "x" .. SH .. " | ZeD scale " .. tostring(ZeD.T and ZeD.T.scale))
local was = opt:getValue()

-- The pointer: Mouse.setXY does not hold (the game reads the desktop cursor again every frame), so the menus are told
-- where it is. The list reads the global (its prerender) and its own method (its update); the strip reads its method,
-- which is panel-local. `ptr` is the screen place; the strip's answer is that minus the panel's corner.
local ptr = { x = -5000, y = -5000 }
local realGX, realGY = getMouseX, getMouseY
local overridden = {}
local function pointerOn(menu)
    getMouseX = function() return ptr.x end
    getMouseY = function() return ptr.y end
    menu.getMouseX = function(self) return ptr.x - (self:getAbsoluteX() or 0) end
    menu.getMouseY = function(self) return ptr.y - (self:getAbsoluteY() or 0) end
    overridden[#overridden + 1] = menu
end
local function pointerOff()
    getMouseX, getMouseY = realGX, realGY
    for _, m in ipairs(overridden) do m.getMouseX, m.getMouseY = nil, nil end
    overridden = {}
end

local Q, qi, waitT = {}, 1, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end   -- n ticks to wait, then fn
local function zm() local v = getPlayerContextMenu(0); return v and v._zedMenu end
local apple, menu
local function giveApple()
    local ok, it = pcall(function() return p:getInventory():AddItem("Base.Apple") end)
    apple = ok and it or nil
    return apple
end
local function open(style)
    opt:setValue(style)
    ptr.x, ptr.y = SW - ZeD.T.px(30), math.floor(SH / 3)   -- (the right edge: the submenu has no room on its right)
    getMouseX = function() return ptr.x end
    getMouseY = function() return ptr.y end
    ISInventoryPaneContextMenu.createMenu(0, true, { apple }, ptr.x, ptr.y)
end
local function names(rows)
    local t = {}
    for _, r in ipairs(rows or {}) do t[#t + 1] = r.sep and "|" or tostring(r.def and r.def.name) end
    return table.concat(t, ", ")
end
local function zone(m, id)
    for _, z in ipairs(m._hitZones or {}) do if z.id == id then return z end end
end
local function center(z) return z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2) end

-- ---------------------------------------------------------------- the list
local top, sub, px, eatAt
step(2, function()
    if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    giveApple()
    check(apple ~= nil, "LIST an apple to right-click")
end)
step(20, function() open(2) end)
step(30, function()
    menu = zm()
    check(menu and menu._levels ~= nil, "LIST the list style opened (class " .. tostring(menu and menu.Type) .. ")")
    if not (menu and menu._levels) then return end
    pointerOn(menu)
    top = menu._levels[1]
    say("LIST top level x=" .. top.x .. " w=" .. top.w .. " | rows: " .. names(top.rows))
    local eat = nil
    for i, r in ipairs(top.rows) do if r.def and tostring(r.def.name):find("Eat") and not eat then eat = i end end
    check(eat ~= nil, "LIST an Eat row")
    if not eat then return end
    local z = zone(menu, "row:1:" .. eat)
    eatAt = z and { center(z) }
    -- (the menu opens with its first live row selected, and Eat is that row: the pointer first goes to another row, then
    -- onto Eat, the way a hand arrives; the "still on the preselected first row" case is noted below)
    local zo = zone(menu, "row:1:" .. (eat + 2))
    if zo then ptr.x, ptr.y = center(zo) end
end)
local eatT
step(6, function() if eatAt then ptr.x, ptr.y = eatAt[1], eatAt[2]; eatT = getTimestampMs() end end)
-- the pointer rests perfectly still on Eat: the submenu opens once it has rested 180 ms. Waited on the clock, not on
-- ticks (the list's update runs every 100 ms whatever the frame rate), up to 600 ms; the check reads the list's state
-- when it fails.
step(1, function()
    local el = eatT and (getTimestampMs() - eatT) or 0
    local opened = menu and menu._levels and menu._levels[2] ~= nil
    if not opened and el < 600 then return "again" end
    check(opened, "LIST a pointer perfectly still on Eat opens its submenu (" .. el .. " ms; nav " .. tostring(menu and menu._nav)
        .. ", hoverRow " .. tostring(menu and menu._hoverRow) .. ", hoverLi " .. tostring(menu and menu._hoverLi)
        .. ", sel " .. tostring(top and top.sel) .. ")")
end)
for j = 1, 40 do   -- (a real hand never rests exactly: one pixel of jitter every 3 ticks, 40 times: well past the 180 ms rest whatever the frame rate)
    step(3, function() ptr.x = ptr.x + ((j % 2 == 1) and 1 or -1) end)
end
step(12, function() end)
step(12, function()
    if not menu then return end
    sub = menu._levels[2]
    if not sub then say("INFO diag ptr " .. ptr.x .. "," .. ptr.y .. " hoverRow " .. tostring(menu._hoverRow) .. " sel " .. tostring(top.sel) .. " lastM " .. tostring(menu._lastMx) .. "," .. tostring(menu._lastMy) .. " levelAt " .. tostring(menu:_levelAt(ptr.x, ptr.y)) .. " mouseX " .. tostring(menu:getMouseX()) .. " eatAt " .. tostring(eatAt and eatAt[1]) .. "," .. tostring(eatAt and eatAt[2]) .. " top " .. top.x .. "," .. top.y .. "," .. top.w .. "," .. top.h) end
    check(sub ~= nil, "LIST the Eat submenu opened on hover")
    if not sub then return end
    say("LIST submenu x=" .. sub.x .. " w=" .. sub.w .. " (" .. (sub.x < top.x and "left of" or "right of") .. " the parent) | rows: " .. names(sub.rows))
    shot("list_natural")
    -- slid over the parent: its left edge a third of the way into it (clamped where the screen leaves room)
    sub.x = math.max(ZeD.T.px(8), math.min(top.x + math.floor(top.w / 3), SW - ZeD.T.px(8) - sub.w))
    local overlap = math.min(top.x + top.w, sub.x + sub.w) - math.max(top.x, sub.x)
    check(overlap > top.w / 4, "LIST the submenu covers a good part of its parent (" .. overlap .. " of " .. top.w .. " design pixels)")
    px = math.max(top.x, sub.x) + math.floor(overlap / 2)
end)
step(4, function() if menu then menu:prerender(); shot("list_overlap") end end)
for ri = 1, 3 do
    step(4, function()
        if not (menu and sub and menu._ctx.open) then return end
        local z = zone(menu, "row:2:" .. ri)
        if not z then check(false, "LIST submenu row " .. ri .. " exists (rows: " .. names(sub.rows) .. ")"); return end
        ptr.x, ptr.y = px, z.y + math.floor(z.h / 2)
    end)
    step(14, function()
        if not (menu and sub and menu._ctx.open) then check(false, "LIST row " .. ri .. ": the menu is still open"); return end
        local inParent = ptr.x >= top.x and ptr.x < top.x + top.w and ptr.y >= top.y and ptr.y < top.y + top.h
        check(inParent, "LIST row " .. ri .. " is also inside the parent's box")
        check(#menu._levels == 2 and menu._levels[2] == sub, "LIST hovering submenu row " .. ri .. " keeps the submenu open (levels " .. #menu._levels .. ")")
        check(sub.sel == ri, "LIST submenu row " .. ri .. " is the selection (" .. tostring(sub.sel) .. ")")
        local ps = top.rows[top.sel] and top.rows[top.sel].def
        check(ps and tostring(ps.name):find("Eat") ~= nil, "LIST the parent stays on Eat (" .. tostring(ps and ps.name) .. ")")
        if ri == 2 then shot("list_hover") end
    end)
end
-- a run of moves up and down the overlap: nothing resets
step(2, function()
    local ok = true
    for i = 1, 8 do
        local z = menu and zone(menu, "row:2:" .. (1 + (i % 3)))
        if z then ptr.x, ptr.y = px + (i % 4), z.y + 4 end
    end
end)
step(16, function()
    check(menu and menu._ctx.open and #menu._levels == 2, "LIST after a run of moves the submenu is still open")
end)
-- a press on the overlap runs the submenu's row, not the parent's
step(2, function()
    if not (menu and sub) then return end
    local z = zone(menu, "row:2:1")
    if z then ptr.x, ptr.y = px, z.y + math.floor(z.h / 2) end
end)
step(12, function()
    if not (menu and menu._ctx.open) then return end
    local before = #menu._levels
    local ate = false
    local def = menu._levels[2] and menu._levels[2].rows[1] and menu._levels[2].rows[1].def
    if def then
        local f = def.onFire
        def.onFire = function(...) ate = true; return nil end   -- (the real action would eat the apple)
        menu:onMouseUp(ptr.x, ptr.y)
        def.onFire = f
    end
    check(ate, "LIST a press on the overlap runs the submenu's row (levels before " .. before .. ")")
    if menu._ctx.open then menu:close() end
end)

-- ---------------------------------------------------------------- the strip
local cells
step(10, function() pointerOff(); open(1) end)
step(30, function()
    menu = zm()
    check(menu and menu._levels == nil and menu._ctx ~= nil, "STRIP the strip style opened (class " .. tostring(menu and menu.Type) .. ")")
    if not menu then return end
    pointerOn(menu)
    ptr.x, ptr.y = -5000, -5000
    local items = menu._ctx.items
    local eat = nil
    for i, d in ipairs(items) do if tostring(d.name):find("Eat") and d.children and #d.children > 0 and not eat then eat = i end end
    check(eat ~= nil, "STRIP an Eat cell with children")
    if not eat then return end
    menu._ctx.selected = eat
    menu:confirm()
end)
step(10, function()
    if not menu then return end
    check(#menu._ctx.path == 1, "STRIP Eat drilled in (path " .. #menu._ctx.path .. ")")
    shot("strip_drilled")
end)
for k = 1, 3 do
    step(4, function()
        if not (menu and menu._ctx.open) then return end
        local z = zone(menu, "ctxcell_" .. k)
        if z then
            -- the zone is panel-local: the screen place is the panel's corner plus it
            ptr.x = (menu:getAbsoluteX() or 0) + z.x + math.floor(z.w / 2)
            ptr.y = (menu:getAbsoluteY() or 0) + z.y + math.floor(z.h / 2)
        else
            say("note: strip cell " .. k .. " has no zone (the drilled strip has fewer cells)")
        end
    end)
    step(14, function()
        if not (menu and menu._ctx.open) then check(false, "STRIP cell " .. k .. ": the menu is still open"); return end
        local z = zone(menu, "ctxcell_" .. k)
        if not z then return end
        check(#menu._ctx.path == 1, "STRIP hovering cell " .. k .. " keeps the drill-down (path " .. #menu._ctx.path .. ")")
        check(menu._ctx.selected == k, "STRIP cell " .. k .. " is the selection (" .. tostring(menu._ctx.selected) .. ")")
    end)
end
step(2, function() if menu and menu._ctx.open then menu:close() end end)

-- ---------------------------------------------------------------- put back
step(10, function()
    pointerOff()
    if apple then pcall(function() p:getInventory():Remove(apple) end) end
    opt:setValue(was)
    say(fails == 0 and "ALL PASS" or ("FAILURES " .. fails))
    say("DONE")
end)

local cur
local function onTick()
    if not cur then
        cur = Q[qi]
        if not cur then Events.OnTick.Remove(onTick); return end
        waitT = cur.n
    end
    if waitT > 0 then waitT = waitT - 1; return end
    local s = cur
    cur = nil
    qi = qi + 1
    local ok, e = pcall(s.fn)
    if ok and e == "again" then qi = qi - 1; return end   -- (a step waiting on the clock runs again next time)
    if not ok then
        fails = fails + 1
        say("ERR step " .. (qi - 1) .. " " .. tostring(e))
    end
end
Events.OnTick.Add(onTick)
say("start")
