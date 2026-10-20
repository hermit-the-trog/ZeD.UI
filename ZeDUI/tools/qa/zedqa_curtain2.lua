-- ZeDUI/tools/qa/zedqa_curtain2.lua  (Oct 19 2026)
-- In game on the ZeD-QA save: the Character window's curtain (its inventory
-- side, right of the drawer) and tab switches while a side is rolled, in both
-- windows. Health open, roll, switch to Skills (still rolled, geometry sane),
-- unroll; the World window rolled on Maps, switch to Forage, unroll.
-- Screenshots zqa_cv_*.png. grep "ZEDQA cv".
local function say(s) print("ZEDQA cv " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_cv_" .. n .. ".png") end) end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function ww() return ZeD_WorldWindow.getWindow() end
local function clickTab(win, id)
    for _, ch in pairs(win:getChildren() or {}) do
        for _, z in ipairs(ch._hitZones or {}) do
            if z.id == "tab:" .. id then ch:onMouseDown(z.x + 2, z.y + 2); return true end
        end
    end
    return false
end
local function geo(w, name)
    local rod = w._rod
    return name .. " rolled " .. tostring(w._rolled) .. " x " .. w:getX() .. " w " .. w:getWidth() .. " right " .. (w:getX() + w:getWidth())
        .. " tab " .. tostring(w._activeTab) .. " content " .. tostring(w._mainContent:isVisible())
        .. " rod " .. tostring(rod and rod:isVisible() and (rod:getX() .. "+" .. rod:getWidth()) or "-")
end
local function roll(w) local r = w._rollBtn; if r then w:onMouseDown(r.x + 2, r.y + 2); return true end; return false end
local x0, w0
at(2, function()
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
at(30, function() say("health tab " .. tostring(clickTab(cw(), "health"))) end)
at(90, function()
    local w = cw(); x0, w0 = w:getX(), w:getWidth()
    say(geo(w, "char before") .. " button " .. tostring(w._rollBtn ~= nil))
    say("roll " .. tostring(roll(w)))
end)
at(150, function() say(geo(cw(), "char rolled")); shot(1) end)
at(160, function() say("skills tab " .. tostring(clickTab(cw(), "skills"))) end)
at(230, function() say(geo(cw(), "char after switch")); shot(2) end)
at(240, function()
    local w = cw()
    for _, z in ipairs(w._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do if e.id == "curtain:unroll" and z.focusable then e.onActivate(w, e); say("A on the tab (" .. z.zone .. ")") end end
    end
end)
at(310, function() say(geo(cw(), "char unrolled") .. " (was x " .. x0 .. " w " .. w0 .. ")") end)
-- the World window: rolled on Maps, then Forage
at(320, function() if not ZeD_WorldWindow.isTabShowing("maps") then ZeD_WorldWindow.openTab(0, "maps") end end)
at(380, function() say("world roll " .. tostring(roll(ww()))) end)
at(440, function() say(geo(ww(), "world rolled")) end)
at(450, function() ZeD_WorldWindow.openTab(0, "forage") end)
at(520, function() say(geo(ww(), "world after switch")); shot(3) end)
at(530, function() ZeD.Curtain.unroll(ww()) end)
at(600, function() say(geo(ww(), "world unrolled")); say("DONE") end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 605 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
