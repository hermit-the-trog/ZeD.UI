-- ZeDUI/tools/qa/zedqa_framed_ring.lua  (Oct 27 2026)
-- The belt hands' condition ring and the action bar's strip as the windows' framed strip (director,
-- Oct 27 2026: "Make the belt hands' condition ring and the action bar's progress line the same chunky
-- framed strip as the other status bars"). Windows shut, a hammer in the main hand and a second
-- condition item in the off hand:
--   01 dark / small: main 80 per cent (green), off 45 (yellow)
--   02 dark / small: main 15 (red), off at one point of condition (the two-unit least fill)
--   03 high contrast / small: 80 / 45 (two-hairline frames)
--   04 dark / large: 80 / 45
--   07 dark / small: the hammer in both hands (the off hand faded, with Both)
--   05 the action bar: three "checking" steps queued, caught in the second (fill + step lines)
--   06 the action bar just after the queue ends (Done, the strip full in the positive colour)
-- Each shot's line gives the boxes' screen rects for cropping. Puts back the theme, the size, the
-- hands, the conditions, the action bar setting and the windows. Screenshots zqa_fr_*.png;
-- grep "ZEDQA fr". Ends with "ZEDQA fr DONE".
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA fr " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_fr_" .. n .. ".png") end) end
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local B = ZeD.Belt
local inv = p:getInventory()
local was = { base = ZeD.currentBase, size = ZeD.currentSize, p1 = p:getPrimaryHandItem(), p2 = p:getSecondaryHandItem(),
              cw = CWm.isOpen(), ww = WWm.isOpen() }
local opt = ZeD.Settings and ZeD.Settings.actionBarOption
was.ab = opt and opt:getValue()
local Q, qi, waitT = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

-- the main and off hand items: a hammer, and another item with a condition (a weapon or tool)
local main, off
for i = 0, inv:getItems():size() - 1 do
    local it = inv:getItems():get(i)
    pcall(function()
        if not main and it:getFullType() == "Base.Hammer" then main = it
        elseif not off and it:getFullType() ~= "Base.Hammer" and instanceof(it, "HandWeapon")
            and it:getConditionMax() >= 5 and not it:isTwoHandWeapon() then off = it end
    end)
end
if not main then main = inv:AddItem("Base.Hammer"); was.addedMain = main end
if not off then off = inv:AddItem("Base.KitchenKnife"); was.addedOff = off end
was.mc, was.oc = main:getCondition(), off:getCondition()

local function setCond(it, f)
    it:setCondition(math.max(f > 0 and 1 or 0, math.floor(it:getConditionMax() * f + 0.5)))
end
local function rects()
    local hud = B.getHUD()
    if not hud then return "no belt" end
    local t, hx, hy = {}, hud:getAbsoluteX(), hud:getAbsoluteY()
    for _, b in ipairs(hud._boxes or {}) do
        if b.kind == "hand" then
            t[#t + 1] = string.format("%s x%d y%d s%d", b.which == "p" and "main" or "off", hx + b.x, hy + b.y, b.w)
        end
    end
    local c1, c2 = B.cond(main), B.cond(off)
    return table.concat(t, " ") .. string.format(" | main %s off %s | %s %s hair %d", tostring(c1 and math.floor(c1 * 100 + 0.5)),
        tostring(c2 and math.floor(c2 * 100 + 0.5)), ZeD.currentBase, ZeD.currentSize, ZeD.T.hair)
end

-- (a step runs, then waits its n ticks)
step(60, function()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(pn)
    else
        if CWm.isOpen() then CWm.toggle(pn) end
        if WWm.isOpen() then WWm.close() end
    end
    ZeD.applyTheme("dark", nil, "small")
    setCond(main, 0.80); setCond(off, 0.45)
    p:setPrimaryHandItem(main); p:setSecondaryHandItem(off)
    say("main " .. main:getFullType() .. " off " .. off:getFullType())
end)
step(20, function() say("01 " .. rects()); shot("01_dark_small") end)
step(40, function() setCond(main, 0.15); off:setCondition(1) end)
step(20, function() say("02 " .. rects()); shot("02_low") end)
step(60, function() setCond(main, 0.80); setCond(off, 0.45); ZeD.applyTheme("hicon", nil, "small") end)
step(20, function() say("03 " .. rects()); shot("03_hicon") end)
step(60, function() ZeD.applyTheme("dark", nil, "large") end)
step(20, function() say("04 " .. rects()); shot("04_dark_large") end)
-- 07: one item in both hands (the off hand shows it faded with Both), dark / small
step(60, function() ZeD.applyTheme("dark", nil, "small"); p:setSecondaryHandItem(main) end)
step(20, function() say("07 " .. rects()); shot("07_both_hands") end)
step(20, function() p:setSecondaryHandItem(off) end)

-- the action bar: three steps queued
local Check = ISBaseTimedAction:derive("ISCheckGearAction")
function Check:isValid() return true end
function Check:waitToStart() return false end
function Check:update() end
function Check:start() end
function Check:stop() ISBaseTimedAction.stop(self) end
function Check:perform() ISBaseTimedAction.perform(self) end
function Check:new(chr, item, t)
    local o = ISBaseTimedAction.new(self, chr)
    o.item, o.maxTime, o.stopOnWalk, o.stopOnRun = item, t, false, false
    return o
end
local function layer()
    local L = ZeD.ActionBar and ZeD.ActionBar._layers and ZeD.ActionBar._layers[pn]
    if not L then return "no layer" end
    return string.format("layer x%d y%d w%d h%d k%d", L:getX(), L:getY(), L:getWidth(), L:getHeight(), L._k or -1)
end
step(20, function()
    ZeD.applyTheme("dark", nil, "small")
    if opt then opt:setValue(1) end
end)
step(300, function()
    for _ = 1, 3 do ISTimedActionQueue.add(Check:new(p, main, 200)) end
end)
step(5, function()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local cur = q and q.queue and q.queue[1]
    say("05 " .. layer() .. " | queue " .. tostring(q and q.queue and #q.queue) .. " step " .. tostring(cur and cur.Type))
    shot("05_bar_queue")
end)
local polls = 0
local function waitDone()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    polls = polls + 1
    if (q and q.queue and #q.queue > 0) and polls < 120 then table.insert(Q, qi + 1, { n = 5, fn = waitDone }); return end
    table.insert(Q, qi + 1, { n = 8, fn = function() say("06 " .. layer()); shot("06_bar_done") end })
end
step(5, waitDone)
step(90, function()
    pcall(function() ISTimedActionQueue.clear(p) end)
    if opt and was.ab then opt:setValue(was.ab) end
    main:setCondition(was.mc); off:setCondition(was.oc)
    p:setPrimaryHandItem(was.p1); p:setSecondaryHandItem(was.p2)
    if was.addedMain then inv:Remove(was.addedMain) end
    if was.addedOff then inv:Remove(was.addedOff) end
    ZeD.applyTheme(was.base, nil, was.size)
    if was.cw and was.ww then CWm.toggleBothPaired(pn)
    else
        if was.cw then CWm.toggle(pn) end
    end
end)
step(30, function() say("DONE") end)

local function onTick()
    if waitT > 0 then waitT = waitT - 1; return end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnTick.Remove(onTick); return end
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(err)) end
    waitT = s.n
end
Events.OnTick.Add(onTick)
