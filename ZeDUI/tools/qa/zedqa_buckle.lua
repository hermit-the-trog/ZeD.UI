-- ZeDUI/tools/qa/zedqa_buckle.lua  (Oct 19 2026)
-- In game on the ZeD-QA save: the buckle sits on the screen's centre, the belt
-- may sit off centre around it.
--   no watch worn: the buckle centre against the screen centre;
--   a left-wrist CaZio on the belt: the belt grows, the buckle stays put;
--   a right-wrist Timez Easy Reader: the same.
-- Screenshots zqa_bk_*.png. grep "ZEDQA bk".
local p = getPlayer()
local function say(s) print("ZEDQA bk " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_bk_" .. n .. ".png") end) end
local hud = ZeD.Belt.getHUD()
local opt = ZeD.Settings.watchPlaceOption
local was = opt:getValue()
local inv = p:getInventory()
local w1, w2
local function wear(it) p:setWornItem(it:getBodyLocation(), it) end
local function watchBox() for _, b in ipairs(hud._boxes) do if b.kind == "watch" then return b end end end
local function centre(tag)
    local b = hud._buckle
    local bc = hud:getAbsoluteX() + b.x + b.w / 2
    local sc = getPlayerScreenLeft(0) + getPlayerScreenWidth(0) / 2
    local wb = watchBox()
    say("centre " .. bc .. " vs screen " .. sc .. " | belt x " .. hud:getX() .. " w " .. hud:getWidth()
        .. " | delta " .. (bc - sc) .. " | " .. tag .. " watch " .. tostring(wb and (wb.plate .. " wrist " .. wb.wrist) or "none"))
end
at(2, function() opt:setValue(1) end)
at(10, function()
    centre("bare")
    shot(1)
end)
at(20, function()
    w1 = inv:AddItem("Base.WristWatch_Left_DigitalBlack"); wear(w1)
    say("worn " .. tostring(w1:getBodyLocation()))
end)
at(60, function()
    centre("cazio")
    shot(2)
end)
at(70, function()
    p:removeWornItem(w1); inv:Remove(w1); w1 = nil
    w2 = inv:AddItem("Base.WristWatch_Right_ClassicBrown"); wear(w2)
    say("worn " .. tostring(w2:getBodyLocation()))
end)
at(110, function()
    centre("timez")
    shot(3)
end)
at(120, function()
    if w1 then p:removeWornItem(w1); inv:Remove(w1) end
    if w2 then p:removeWornItem(w2); inv:Remove(w2) end
    opt:setValue(was)
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 125 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
