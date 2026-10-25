-- ZeDUI/tools/qa/gallery_belt_watches.lua  (Oct 25 2026)
-- The gallery's Watches card after the belt's hands swapped ends (a left-wrist watch now sits
-- left of the off hand): the mini watch on the belt for four models (CaZio digital, Timez,
-- CaZio classic, Timez red) by day, the windows shut. Screenshots/gbw_<model>.png; each
-- watch box's screen rect is printed for the crops ("box ..."). What the wrist wore, the
-- time of day, the watch option and the windows go back. grep "ZEDQA gbw".
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA gbw " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("gbw_" .. n .. ".png") end); say("shot gbw_" .. n) end
local inv = p:getInventory()
local B = ZeD.Belt
local opt = ZeD.Settings.watchPlaceOption
local optWas = opt:getValue()
local gt = getGameTime()
local todWas = gt:getTimeOfDay()
local winsWere = ZeD_CharacterWindow.isOpen()
local MODELS = { "DigitalBlack", "DigitalTimez", "ClassicGold", "DigitalRed" }
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

-- the watch worn now, put back at the end
local kit, kitLoc
pcall(function()
    local worn = p:getWornItems()
    for i = 0, worn:size() - 1 do
        local wi = worn:get(i)
        if instanceof(wi:getItem(), "AlarmClockClothing") then kit, kitLoc = wi:getItem(), wi:getLocation() end
    end
end)
local cur
local function wear(name)
    if cur then p:removeWornItem(cur, false); inv:Remove(cur); cur = nil end
    if kit then pcall(function() p:removeWornItem(kit, false) end) end
    if not name then
        if kit then p:setWornItem(kitLoc, kit) end
        return
    end
    cur = inv:AddItem("Base.WristWatch_Left_" .. name)
    p:setWornItem(cur:getBodyLocation(), cur)
end

step(2, function()
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    opt:setValue(1)            -- the watch on the belt
    gt:setTimeOfDay(13.0)
    pcall(function() Mouse.setXY(20, 20) end)
    say("kit watch " .. tostring(kit and kit:getFullType()))
end)
for _, name in ipairs(MODELS) do
    step(10, function() wear(name) end)
    step(90, function()
        local hud = B.getHUD()
        local x, y, w = B.watchScreen()
        local h = 0
        for _, b in ipairs(hud and hud._boxes or {}) do if b.kind == "watch" then h = b.h end end
        say(string.format("box %s %s,%s %sx%s", name, tostring(x), tostring(y), tostring(w), tostring(h)))
        shot(name)
    end)
end
step(10, function()
    wear(nil)
    opt:setValue(optWas)
    gt:setTimeOfDay(todWas)
    if winsWere and not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    say("put back: watch " .. tostring(kit and kit:getFullType()) .. ", time " .. string.format("%.2f", todWas))
end)
step(10, function() say("DONE") end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
