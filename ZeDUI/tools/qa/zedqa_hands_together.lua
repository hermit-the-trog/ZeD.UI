-- ZeDUI/tools/qa/zedqa_hands_together.lua  (Oct 27 2026)
-- The belt's hands together at the left end (director, Oct 27 2026: "Put the hands together at the left end"),
-- the main hand 56 units and the off hand 44, 6 apart; one item in both hands keeps the main hand's circle and
-- the off hand peeks 14 units from under it ("keeping the primary the circle, and having the secondary peeking
-- from behind when an item is in both hands"). Windows shut; a hammer in the main hand, a knife in the off hand.
--   01 dark / small, two items          02 the hammer in both hands (the off hand peeking)
--   03 both hands, High contrast         04 both hands, Large text
--   05 a left-wrist watch, both hands (the watch moves in with the off hand)
--   06 a right-wrist watch and a pistol in the main hand (the ammo pouch, then the watch, then the strap)
--   07 the controller's mark on the peeking off hand (the pointing hand round its crescent only)
-- Checks (PASS / FAIL lines): the sizes, the gap, the peek, the order (hands before the slots, the Messages note
-- last), what a click at the crescent and under the main hand finds, the slots' place on screen not moving when
-- the off hand slides in, and the controller's walk from slot 1 (Left: the main hand, then the off hand).
-- Puts back the theme, the size, the hands, the conditions, the watch setting and the windows.
-- Screenshots zqa_ht_*.png; grep "ZEDQA ht". Ends with "ZEDQA ht DONE".
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA ht " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ht_" .. n .. ".png") end) end
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local B = ZeD.Belt
local hud = B.getHUD()
local inv = p:getInventory()
local wopt = ZeD.Settings.watchPlaceOption
local was = { base = ZeD.currentBase, size = ZeD.currentSize, p1 = p:getPrimaryHandItem(), p2 = p:getSecondaryHandItem(),
              cw = CWm.isOpen(), ww = WWm.isOpen(), watch = wopt and wopt:getValue() }
local Q, qi, waitT = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

local main, off
for i = 0, inv:getItems():size() - 1 do
    local it = inv:getItems():get(i)
    pcall(function()
        if not main and it:getFullType() == "Base.Hammer" then main = it
        elseif not off and it:getFullType() == "Base.KitchenKnife" then off = it end
    end)
end
if not main then main = inv:AddItem("Base.Hammer"); was.addedMain = main end
if not off then off = inv:AddItem("Base.KitchenKnife"); was.addedOff = off end
was.mc, was.oc = main:getCondition(), off:getCondition()
local function setCond(it, f) it:setCondition(math.max(1, math.floor(it:getConditionMax() * f + 0.5))) end

local function name(b) return (b.kind == "hand" and (b.which == "p" and "MAIN" or (b.peek and "off(peek)" or "OFF"))) or (b.kind == "slot" and ("#" .. b.i)) or b.kind end
local function desc()
    local t = {}
    for _, b in ipairs(hud._boxes) do t[#t + 1] = name(b) .. "@" .. b.x .. "/" .. b.w end
    return table.concat(t, " ")
end
local function find(kind, which)
    for i, b in ipairs(hud._boxes) do if b.kind == kind and (which == nil or b.which == which) then return b, i end end
    return nil
end
-- the screen x of slot 1 (the slots and the buckle stay put whatever the hands do)
local slotX = nil
local function slot1X()
    local b = find("slot")
    return b and (hud:getAbsoluteX() + b.x) or nil
end

local function layout(tag, two)
    local T = ZeD.T
    local s, si = find("hand", "s")
    local m, mi = find("hand", "p")
    say(tag .. " | " .. desc() .. " | " .. ZeD.currentBase .. " " .. ZeD.currentSize .. " | belt x" .. hud:getAbsoluteX() .. " y" .. hud:getAbsoluteY()
        .. " w" .. hud:getWidth() .. " h" .. hud:getHeight())
    if not check(s and m, tag .. ": both hands are on the belt") then return end
    check(m.w == T.px(56) and s.w == T.px(44), tag .. ": the main hand is 56 units, the off hand 44 (" .. m.w .. ", " .. s.w .. " px; 56u = " .. T.px(56) .. ")")
    check(si < mi, tag .. ": the off hand comes before the main hand")
    local bx = hud._boxes
    local firstSlot = nil
    for i, b in ipairs(bx) do if b.kind == "slot" then firstSlot = firstSlot or i end end
    check(firstSlot == nil or firstSlot > mi, tag .. ": the hands sit before the slots (the left end)")
    local inc = true
    for i = 2, #bx do if bx[i].x <= bx[i - 1].x then inc = false end end
    check(inc, tag .. ": the boxes run left to right")
    local lamp, li = find("lamp")
    if lamp then check(li == #bx, tag .. ": the Messages note is last") end
    if two then
        check(s.peek == true and m.x - s.x == T.px(14), tag .. ": the off hand peeks 14 units from under the main hand (" .. (m.x - s.x) .. " px)")
        check(s.peekW and s.peekW > T.px(14) and s.peekW < s.w, tag .. ": the crescent's mark is " .. tostring(s.peekW) .. " px wide")
        local cy = s.y + math.floor(s.h / 2)
        check(hud:boxAt(s.x + 1, cy) == s, tag .. ": a click at the crescent finds the off hand")
        check(hud:boxAt(s.x + s.w - 2, cy) == m, tag .. ": a click where the two overlap finds the main hand")
    else
        check(not s.peek and m.x - (s.x + s.w) == T.px(6), tag .. ": the hands are 6 units apart (" .. (m.x - (s.x + s.w)) .. " px)")
        check(hud:boxAt(s.x + s.w - 2, s.y + math.floor(s.h / 2)) == s, tag .. ": a click at the off hand's right edge finds the off hand")
    end
    local sx = slot1X()
    if slotX == nil then slotX = sx
    else check(sx == slotX, tag .. ": slot 1 stays in place on screen (" .. tostring(sx) .. ", was " .. tostring(slotX) .. ")") end
    return s, m
end

-- a watch on one wrist; what the wrist wore before goes back at the end
local worn = {}
local function wearNew(full)
    local it = inv:AddItem(full)
    local loc = it:getBodyLocation()
    local prev = p:getWornItem(loc)
    worn[#worn + 1] = { it = it, loc = loc, prev = prev }
    p:setWornItem(loc, it)
    return it
end
local function takeOff(it)
    for _, w in ipairs(worn) do
        if w.it == it then
            p:removeWornItem(it); inv:Remove(it)
            if w.prev and inv:contains(w.prev) then p:setWornItem(w.loc, w.prev) end
        end
    end
end

-- (a step runs, then waits its n ticks)
step(60, function()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(pn)
    else
        if CWm.isOpen() then CWm.toggle(pn) end
        if WWm.isOpen() then WWm.close() end
    end
    if wopt then wopt:setValue(2) end    -- no watch on the belt yet
    ZeD.applyTheme("dark", nil, "small")
    setCond(main, 0.80); setCond(off, 0.50)
    p:setPrimaryHandItem(main); p:setSecondaryHandItem(off)
end)
step(20, function() layout("01 two items", false); shot("01_two") end)
step(30, function() p:setSecondaryHandItem(main) end)
step(20, function() layout("02 both hands", true); shot("02_both") end)
step(60, function() ZeD.applyTheme("hicon", nil, "small") end)
step(20, function() slotX = nil; layout("03 both, high contrast", true); shot("03_both_hicon") end)
step(60, function() ZeD.applyTheme("dark", nil, "large") end)
step(20, function() slotX = nil; layout("04 both, large", true); shot("04_both_large") end)
step(60, function() ZeD.applyTheme("dark", nil, "small"); p:setSecondaryHandItem(off) end)
-- the controller from slot 1: Left reaches the main hand, then the off hand, then leaves
step(20, function()
    slotX = nil
    layout("pad two items", false)
    hud._gp = { idx = hud:_firstSlotIdx(), inList = false, row = 1, list = {} }
    local b0 = hud:_gpBox()
    check(b0 and b0.kind == "slot" and b0.i == 1, "pad: the belt starts on slot 1 (" .. tostring(b0 and name(b0)) .. ")")
    hud:onJoypadDirLeft()
    local b1 = hud:_gpBox()
    check(b1 and b1.kind == "hand" and b1.which == "p", "pad: Left from slot 1 is the main hand (" .. tostring(b1 and name(b1)) .. ")")
    hud:onJoypadDirLeft()
    local b2 = hud:_gpBox()
    check(b2 and b2.kind == "hand" and b2.which == "s", "pad: Left again is the off hand (" .. tostring(b2 and name(b2)) .. ")")
    hud._gp = nil
    if wopt then wopt:setValue(1) end
    was.w1 = wearNew("Base.WristWatch_Left_DigitalBlack")
    p:setSecondaryHandItem(main)
end)
step(40, function()
    local s = layout("05 left wrist, both hands", true)
    local wb = find("watch")
    check(wb and s and wb.x + wb.w + ZeD.T.px(8) == s.x, "05: the left-wrist watch sits beside the peeking off hand")
    shot("05_leftwatch_both")
end)
step(20, function()
    takeOff(was.w1)
    was.w2 = wearNew("Base.WristWatch_Right_ClassicBrown")
    was.gun = inv:AddItem("Base.Pistol")
    p:setPrimaryHandItem(was.gun); p:setSecondaryHandItem(off)
end)
step(60, function()
    slotX = nil
    local _, m = layout("06 right wrist, pistol", false)
    local am, ai = find("ammo")
    local wb, wi = find("watch")
    local _, mi = find("hand", "p")
    local s1 = find("slot")
    check(am and ai == mi + 1, "06: the ammo pouch is beside the main hand")
    check(wb and am and wi == ai + 1 and (not s1 or wb.x + wb.w < s1.x), "06: the right-wrist watch is outside the pouch, before the strap")
    local _, _, _, side = B.watchScreen()
    check(side == "left", "06: the full watch opens to the right of the small one (" .. tostring(side) .. ")")
    shot("06_rightwatch_pistol")
end)
step(20, function()
    takeOff(was.w2)
    if wopt then wopt:setValue(2) end
    p:setPrimaryHandItem(main); p:setSecondaryHandItem(main)
end)
-- the controller's mark on the peeking off hand (the mark is shown as if the pad were in use)
step(40, function()
    local s, si = find("hand", "s")
    hud._mkOpts.pad, hud._mkSolid.pad = true, true
    hud._gp = { idx = si, inList = false, row = 1, list = {} }
end)
step(20, function()
    local s = find("hand", "s")
    say("07 off hand x" .. (hud:getAbsoluteX() + s.x) .. " y" .. (hud:getAbsoluteY() + s.y) .. " s" .. s.w .. " peekW " .. tostring(s.peekW))
    shot("07_pad_peek")
end)
step(20, function()
    hud._gp = nil
    hud._mkOpts.pad, hud._mkSolid.pad = nil, nil
    main:setCondition(was.mc); off:setCondition(was.oc)
    p:setPrimaryHandItem(was.p1); p:setSecondaryHandItem(was.p2)
    if was.gun then inv:Remove(was.gun) end
    if was.addedMain then inv:Remove(was.addedMain) end
    if was.addedOff then inv:Remove(was.addedOff) end
    if wopt and was.watch then wopt:setValue(was.watch) end
    ZeD.applyTheme(was.base, nil, was.size)
    if was.cw and was.ww then CWm.toggleBothPaired(pn)
    elseif was.cw then CWm.toggle(pn) end
end)
step(30, function()
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local function onTick()
    if waitT > 0 then waitT = waitT - 1; return end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnTick.Remove(onTick); return end
    local ok, err = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. qi .. ": " .. tostring(err)) end
    waitT = s.n
end
Events.OnTick.Add(onTick)
say("start")
