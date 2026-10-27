-- ZeDUI/tools/qa/zedqa_belt_hands.lua  (Oct 25 2026)
-- RETIRED Oct 27 2026: the hands sit together at the left end now; zedqa_hands_together.lua replaces it in regression.txt.
-- The belt as seen from behind (director, Oct 25 2026: "Swap the hands: left hand at the left
-- end, right hand at the right end, belt slots stay"): the off hand at the left end, the main
-- hand at the right end, the slots between in key order; a left-wrist watch left of the off hand,
-- a right-wrist watch right of the main hand (the full watch pops on that side); the Messages
-- note last; the boxes in left-to-right order, as the controller walks them (it starts on the
-- first slot, Left from there is the off hand). The wrists' own watches go back at the end.
-- Screenshots zqa_bh_*.png; grep "ZEDQA bh".
local p = getPlayer()
local function say(s) print("ZEDQA bh " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_bh_" .. n .. ".png") end) end
local B = ZeD.Belt
local hud = B.getHUD()
local inv = p:getInventory()
local opt = ZeD.Settings.watchPlaceOption
local was = opt:getValue()
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end

local function name(b) return (b.kind == "hand" and (b.which == "p" and "MAIN" or "OFF")) or (b.kind == "slot" and ("#" .. b.i)) or b.kind end
local function desc()
    local t = {}
    for _, b in ipairs(hud._boxes) do t[#t + 1] = name(b) .. "@" .. b.x end
    return table.concat(t, " ")
end
local function find(kind, which)
    for i, b in ipairs(hud._boxes) do if b.kind == kind and (which == nil or b.which == which) then return b, i end end
    return nil
end
local function order(tag)
    local bx = hud._boxes
    local inc = true
    for i = 2, #bx do if bx[i].x <= bx[i - 1].x then inc = false end end
    check(inc, tag .. ": the boxes run left to right (" .. desc() .. ")")
    local s, si = find("hand", "s")
    local m, mi = find("hand", "p")
    local between = s ~= nil and m ~= nil
    for i, b in ipairs(bx) do if b.kind == "slot" and not (si and mi and i > si and i < mi) then between = false end end
    check(s and m and s.x < m.x and between, tag .. ": the off hand at the left end, the main hand at the right, the slots between")
    local lamp, li = find("lamp")
    if lamp then check(li == #bx, tag .. ": the Messages note is last on the right") end
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

local w1, w2
at(2, function()
    opt:setValue(1)   -- the watch on the belt
    w1 = wearNew("Base.WristWatch_Left_DigitalBlack")
end)
at(40, function()
    local s = order("left wrist")
    local wb = find("watch")
    check(wb and s and wb.x + wb.w <= s.x, "left wrist: the watch is left of the off hand")
    local _, _, _, side = B.watchScreen()
    check(side == "left", "left wrist: the full watch pops at the left end (" .. tostring(side) .. ")")
    -- the controller: the first slot first, Left from there is the off hand
    hud._gp = { idx = hud:_firstSlotIdx(), inList = false, row = 1, list = {} }
    local b0 = hud:_gpBox()
    check(b0 and b0.kind == "slot" and b0.i == 1, "pad: the belt starts on slot 1 (" .. tostring(b0 and name(b0)) .. ")")
    hud:onJoypadDirLeft()
    local b1 = hud:_gpBox()
    check(b1 and b1.kind == "hand" and b1.which == "s", "pad: Left from slot 1 is the off hand (" .. tostring(b1 and name(b1)) .. ")")
    hud._gp = nil
    shot("1_left_wrist")
end)
at(50, function() takeOff(w1); w2 = wearNew("Base.WristWatch_Right_ClassicBrown") end)
at(90, function()
    local _, m = order("right wrist")
    local wb = find("watch")
    check(wb and m and wb.x >= m.x + m.w, "right wrist: the watch is right of the main hand")
    local _, _, _, side = B.watchScreen()
    check(side == "right", "right wrist: the full watch pops at the right end (" .. tostring(side) .. ")")
    shot("2_right_wrist")
end)
at(100, function() takeOff(w2); opt:setValue(was) end)
at(130, function()
    order("as worn")
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then fails = fails + 1; say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 135 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
