-- ZeDUI/tools/qa/zedqa_curtain.lua  (Oct 19 2026)
-- In game on the ZeD-QA save: the World window's curtain (WindowCurtain.lua).
-- Opens both windows and the Maps tab, presses the title's roll triangle,
-- shoots mid-roll and rolled, checks the window narrowed and the rod sits
-- over the old side, checks the controller stop, unrolls through it, then
-- rolls again and closes the Maps tab (the side must come back by itself).
-- Screenshots zqa_cu_*.png. grep "ZEDQA cu".
local function say(s) print("ZEDQA cu " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function ww() return ZeD_WorldWindow.getWindow() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_cu_" .. n .. ".png") end) end
local x0, w0
at(2, function()
    if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
at(30, function()
    local w, cw = ww(), ZeD_CharacterWindow.getWindow()   -- (beside the Character window, as on a fresh load)
    if w and cw and not w._rolled then w:setX(cw:getX() + cw:getWidth() + ZeD.T.px(8)) end
    if not ZeD_WorldWindow.isTabShowing("maps") then ZeD_WorldWindow.openTab(0, "maps") end
end)
at(90, function()
    local w = ww()
    x0, w0 = w:getX(), w:getWidth()
    local r = w._rollBtn
    say("before: x " .. x0 .. " w " .. w0 .. " title " .. tostring(w.title) .. " button " .. tostring(r and (r.x .. "," .. r.y .. " " .. r.w)))
    if r then w:onMouseDown(r.x + 2, r.y + 2) end
end)
at(96, function() shot(1) end)
at(140, function()
    local w = ww(); local rod = w._rod
    say("rolled " .. tostring(w._rolled) .. ": x " .. w:getX() .. " w " .. w:getWidth() .. " (sum " .. (w:getX() + w:getWidth()) .. " was " .. (x0 + w0) .. ")"
        .. " rod " .. tostring(rod and (rod:getX() .. "," .. rod:getY() .. " " .. rod:getWidth() .. "x" .. rod:getHeight()))
        .. " content " .. tostring(w._mainContent:isVisible()) .. " title " .. tostring(w.title))
    local Focus = ZeD.Input.Focus
    local ids = {}
    for _, z in ipairs(w._focusRing or {}) do
        if z.focusable then for _, e in ipairs(z.elements or {}) do if e.id and tostring(e.id):find("curtain") then ids[#ids + 1] = z.zone .. ":" .. e.id end end end
    end
    say("pad stops: " .. table.concat(ids, ", "))
    shot(2)
end)
at(150, function()
    local w = ww()
    for _, z in ipairs(w._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do if e.id == "curtain:unroll" then e.onActivate(w, e); say("A on the tab") end end
    end
end)
at(156, function() shot(3) end)
at(220, function()
    local w = ww()
    say("unrolled " .. tostring(not w._rolled) .. ": x " .. w:getX() .. " w " .. w:getWidth() .. " content " .. tostring(w._mainContent:isVisible())
        .. " rod " .. tostring(w._rod and w._rod:isVisible()))
    local r = w._rollBtn
    if r then w:onMouseDown(r.x + 2, r.y + 2) end
end)
at(280, function() say("rolled again " .. tostring(ww()._rolled)); ZeD_WorldWindow.openTab(0, "maps", true) end)
at(360, function()
    local w = ww()
    say("tab closed: rolled " .. tostring(w._rolled) .. " x " .. w:getX() .. " w " .. w:getWidth() .. " content " .. tostring(w._mainContent:isVisible()) .. " drawer " .. tostring(w._drawerOpen))
    shot(4)
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 365 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
