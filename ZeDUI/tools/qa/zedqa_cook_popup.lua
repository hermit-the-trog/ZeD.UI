-- ZeDUI/tools/qa/zedqa_cook_popup.lua  (Nov 3 2026, QA; punch list 80: is the Cooking tab's open Dish list drawn?)
-- The Cooking tab with a pot of water, a carrot and a potato; the Dish list opened by the tab's own click and left open
-- two seconds; two pictures 60 frames apart, the list's place and its rows logged. Then the Sort list the same way, and
-- the Crafting tab's open list for comparison is not needed (the Vehicle tab's Sort list shows in its own pictures).
-- Shots zqa_ckp_<w>x<h>_*.png; grep "ZEDQA ckp".
local function say(s) print("ZEDQA ckp " .. tostring(s)) end
if ZEDQA_HOME then ZEDQA_HOME("ckp") end
local p = getPlayer()
local CK = ZeD and ZeD.CookingTab
if not (p and CK) then say("ERR the Cooking tab is not loaded"); say("DONE"); return end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local inv = p:getInventory()
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ckp_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local function CW() return ZeD_CharacterWindow.getWindow() end
local function S() local w = CW(); return w and w._cook end
local function press(id)
    local s, w = S(), CW()
    local z = s and s.byId and s.byId[id]
    if not (z and w) then say("(no zone " .. id .. ")"); return false end
    CK.onClick(w, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    return true
end
local function stripHas()
    local strip = CW() and CW()._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do if z.id == "tab:cooking" then return z end end
    return nil
end
local made = {}
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function waitFor(n, max, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
local function logPop(tag)
    local s = S(); if not s then return end
    local g = (s.popup == "dish" and s.dishGeo) or (s.popup == "sort" and s.sortGeo) or nil
    local zs = {}
    for _, z in ipairs(s.popZones or {}) do zs[#zs + 1] = string.format("%s@%d,%d %dx%d", z.id, z.x, z.y, z.w, z.h) end
    local pnl = s.panel
    say(string.format("%s: popup %s, geo %s, panel %s abs %d,%d size %dx%d; rows [%s]", tag, tostring(s.popup),
        g and string.format("%d,%d w%d", g.x, g.y, g.w) or "nil", tostring(pnl and pnl.Type),
        pnl and pnl:getAbsoluteX() or -1, pnl and pnl:getAbsoluteY() or -1, pnl and pnl:getWidth() or -1, pnl and pnl:getHeight() or -1,
        table.concat(zs, "; ")))
end

step(120, function()
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    end)
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
    local pot = inv:AddItem("Base.Pot"); made[#made + 1] = pot
    pcall(function() local fc = pot:getFluidContainer(); fc:addFluid(Fluid.Water, fc:getCapacity()) end)
    for _, ft in ipairs({ "Base.Carrots", "Base.Potato" }) do made[#made + 1] = inv:AddItem(ft) end
end)
waitFor(10, 600, function() return stripHas() ~= nil end, function()
    local w = CW(); local z = stripHas(); if z and w._activeTab ~= "cooking" then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end
end)
waitFor(10, 600, function() local w, s = CW(), S(); return w._activeTab == "cooking" and s and #s.zones > 0 end, function()
    pcall(function() Mouse.setXY(sw - 4, sh - 4) end)
end)
step(30, function() press("cook:dish") end)
step(60, function() logPop("dish open 60"); shot("1_dish_open") end)
step(60, function() logPop("dish open 120"); shot("2_dish_open_later") end)
step(10, function() local s = S(); if s then s.popup = nil end end)
step(20, function() press("cook:sort") end)
step(60, function() logPop("sort open 60"); shot("3_sort_open") end)
step(10, function() local s = S(); if s then s.popup = nil end end)
step(20, function()
    for _, it in ipairs(made) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    say("put back: " .. #made .. " items taken away")
    say("DONE")
end)

local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    if q.cond then
        q.left = (q.left or q.max) - 1
        local ok, done = pcall(q.cond)
        if not (ok and done) and q.left > 0 then return end
        if not (ok and done) then say("WARN step " .. (qi + 1) .. ": waited " .. q.max .. " frames, went on") end
    end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
