-- ZeDUI/tools/qa/zedqa_grid.lua  (Oct 19 2026)
-- In game on the ZeD-QA save: the inventory grid. Switches the character's bag
-- to grid, captures it, opens a cell's card, walks the cells with the
-- simulated pad, goes up to the List | Grid toggle and presses A on List.
-- Puts the view back. grep "ZEDQA grid". Screenshots zqa_grid_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local Focus, Det, IR = ZeD.Input.Focus, ZeD.Input.Detector, ZeD.InventoryRenderer
local function say(s) print("ZEDQA grid " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function tab(id)
    local w = cw(); local strip = w and w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end
local function zone(w, name) for i, z in ipairs(w._focusRing or {}) do if z.zone == name then return i, z end end end
local function where(tag)
    local w = cw(); local z = Focus.getFocusedZone(w); local e = Focus.getFocusedElement(w)
    say(tag .. ": zone=" .. tostring(z and z.zone) .. " el=" .. tostring(e and e.id) .. " item=" .. tostring(e and e.item and e.item:getName()))
end
local was = IR.isGridKey("player")
at(2, function() if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end end)
at(15, function() tab("loot"); Det.setLockedMode(Det.MODE_GAMEPAD); Focus.claimFocus(cw()) end)
at(30, function() IR.setGridKey("player", true) end)
at(60, function()
    local c = cw()._mainContent
    local nx = 0; for _ in pairs(c._itemRenderXMap or {}) do nx = nx + 1 end
    say("grid on: cell " .. tostring(c._gridCell) .. " | cells placed " .. nx .. " | toggle rects " .. #(c._viewToggleRects or {}))
    local _, z = zone(cw(), "charMainInv")
    local e1 = z and z.elements and z.elements[1]
    say("first target: " .. tostring(e1 and e1.id) .. " at " .. tostring(e1 and e1.x) .. "," .. tostring(e1 and e1.y) .. " size " .. tostring(e1 and e1.w) .. "x" .. tostring(e1 and e1.h))
end)
at(70, function() pcall(function() getCore():TakeFullScreenshot("zqa_grid_1.png") end) end)
-- the pad: first cell, right, down, up, up (the toggle), A on List
at(80, function()
    local w = cw(); local zi, z = zone(w, "charMainInv")
    w._focusIdx = zi; z.focusedElementIdx = 1
    local e = z.elements[1]; if e.onFocus then e.onFocus(w, e) end
    where("first cell")
end)
at(90, function() Focus.dispatchJoypadDir(cw(), "right"); where("right (expect the next cell)") end)
at(100, function() Focus.dispatchJoypadDir(cw(), "down"); where("down (expect the cell below)") end)
at(110, function() Focus.dispatchJoypadDir(cw(), "up"); where("up") end)
at(120, function() Focus.dispatchJoypadDir(cw(), "up"); where("up again (expect the toggle)") end)
at(125, function() pcall(function() getCore():TakeFullScreenshot("zqa_grid_2.png") end) end)
-- a cell's card: A on a cell
at(130, function()
    local w = cw(); local zi, z = zone(w, "charMainInv")
    for i, e in ipairs(z.elements) do
        if e.item and not (w._mainContent._stacks[e.item] and w._mainContent._stacks[e.item].count > 1) then
            w._focusIdx = zi; z.focusedElementIdx = i; e.onFocus(w, e); e.onActivate(w, e); break
        end
    end
end)
at(160, function() say("card open " .. tostring(cw()._drawerItem ~= nil) .. " item " .. tostring(cw()._drawerItem and cw()._drawerItem:getName())) end)
at(165, function() pcall(function() getCore():TakeFullScreenshot("zqa_grid_3.png") end) end)
at(170, function()
    local w = cw(); local c = w._mainContent
    local sel = c._selectedItems or {}; for k in pairs(sel) do sel[k] = nil end; c._lastClickedItem = nil; w._updateDrawer(c)
    local zi, z = zone(w, "charMainInv")
    for i, e in ipairs(z.elements) do if e.isViewToggle and e.view == "list" then w._focusIdx = zi; z.focusedElementIdx = i; e.onActivate(w, e) end end
end)
at(190, function() say("after A on List: grid " .. tostring(IR.isGridKey("player")) .. " cell " .. tostring(cw()._mainContent._gridCell)) end)
at(200, function()
    IR.setGridKey("player", was)
    Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 205 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
