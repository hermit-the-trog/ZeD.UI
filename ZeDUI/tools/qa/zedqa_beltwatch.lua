-- ZeDUI/tools/qa/zedqa_beltwatch.lua  (Oct 19 2026)
-- In game on the ZeD-QA save: the mini watch on the belt (WatchMini.lua).
--   a left-wrist CaZio: right of the off hand; the face pops the full watch
--   above it; a drag moves it and is kept; it tucks back when left alone;
--   a right-wrist Timez Easy Reader: left of the main hand; Corner mode puts
--   the full watch back in the corner.
-- Screenshots zqa_bw_*.png. grep "ZEDQA bw".
local p = getPlayer()
local function say(s) print("ZEDQA bw " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_bw_" .. n .. ".png") end) end
local hud = ZeD.Belt.getHUD()
local W = ZeD.Watch
local opt = ZeD.Settings.watchPlaceOption
local was = opt:getValue()
local inv = p:getInventory()
local w1, w2
local function wear(it) p:setWornItem(it:getBodyLocation(), it) end
local function watchBox() for _, b in ipairs(hud._boxes) do if b.kind == "watch" then return b end end end
local function hands()
    local out = {}
    for _, b in ipairs(hud._boxes) do if b.kind == "hand" then out[#out + 1] = b.which .. "@" .. b.x end end
    return table.concat(out, " ")
end
at(2, function()
    opt:setValue(1)
    p:getModData().ZeD_WatchPop = nil
    w1 = inv:AddItem("Base.WristWatch_Left_DigitalBlack"); wear(w1)
    say("worn " .. tostring(w1:getBodyLocation()))
end)
at(40, function()
    local b = watchBox()
    say("box " .. tostring(b and (b.plate .. " wrist " .. b.wrist .. " x " .. b.x .. " w " .. b.w)) .. " | hands " .. hands() .. " | belt w " .. hud:getWidth())
    local inst = W.getInstance()
    say("full watch tucked: " .. inst:getWidth() .. "x" .. inst:getHeight())
    shot(1)
end)
at(50, function()
    local b = watchBox()
    hud:onMouseDown(b.x + math.floor(b.w / 2), b.y + math.floor(b.h / 2))   -- the face
end)
at(70, function()
    local inst = W.getInstance()
    local bx, by = ZeD.Belt.watchScreen()
    say("popped " .. tostring(inst._popped) .. " at " .. inst:getX() .. "," .. inst:getY() .. " " .. inst:getWidth() .. "x" .. inst:getHeight() .. " | mini at " .. bx .. "," .. by)
    shot(2)
    -- a drag: press on the strap (not a control), move, release
    inst:onMouseDown(math.floor(inst:getWidth() / 2), 4)
    inst._dragX, inst._dragY = 1500, 500
end)
at(80, function()
    local inst = W.getInstance()
    inst:onMouseUp(0, 0)
    local s = p:getModData().ZeD_WatchPop
    say("dragged to " .. inst:getX() .. "," .. inst:getY() .. " saved " .. tostring(s and (s.x .. "," .. s.y)))
    shot(3)
end)
at(500, function()
    local inst = W.getInstance()
    say("after idle: popped " .. tostring(inst._popped) .. " size " .. inst:getWidth())
end)
at(510, function()
    p:removeWornItem(w1); inv:Remove(w1)
    w2 = inv:AddItem("Base.WristWatch_Right_ClassicBrown"); wear(w2)
end)
at(550, function()
    local b = watchBox()
    say("right wrist: " .. tostring(b and (b.plate .. " wrist " .. b.wrist .. " x " .. b.x)) .. " | hands " .. hands())
    shot(4)
end)
at(560, function() opt:setValue(2) end)
at(600, function()
    local inst = W.getInstance()
    say("corner: box " .. tostring(watchBox() ~= nil) .. " full watch " .. inst:getX() .. "," .. inst:getY() .. " " .. inst:getWidth() .. "x" .. inst:getHeight())
    shot(5)
end)
at(610, function()
    p:removeWornItem(w2); inv:Remove(w2)
    p:getModData().ZeD_WatchPop = nil
    opt:setValue(was)
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 615 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
