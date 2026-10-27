-- ZeDUI/tools/qa/zedqa_ring_squares.lua  (Oct 24 2026)
-- The hands' condition as a ring inset inside the circle ("the bar looks odd in the
-- circle. a ring slightly inset inside would be the better place for it"): a hammer in
-- the main hand and a kitchen knife in the off hand at full, 70 / 45 and 15 per cent,
-- a picture of the belt at each.
-- (This file once also tested ZeD setup's switch that hid the windows' theme, accent and
-- text squares. The squares are gone, replaced by the window box's menu; that half went
-- with them. The window box is tested in zedqa_menu_footer_run.ps1.)
-- The hands, the conditions and the windows are put back. grep "ZEDQA rs".
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA rs " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_rs_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

if not (ZeD and ZeD.Belt and ZeD.Belt._ringArc) then say("ERR the new code is not loaded"); say("DONE"); return end
local was = { p1 = p:getPrimaryHandItem(), p2 = p:getSecondaryHandItem(), pair = false }
local inv = p:getInventory()
local hammer, knife

local function hud() return ZeD.Belt.getHUD and ZeD.Belt.getHUD() end
local function handBoxes()
    local h = hud()
    local out = {}
    for _, b in ipairs(h and h._boxes or {}) do if b.kind == "hand" then out[#out + 1] = b end end
    return out
end
local function setCond(item, f)
    item:setCondition(math.max(0, math.floor(item:getConditionMax() * f + 0.5)))
end

step(10, function()
    hammer = inv:AddItem("Base.Hammer")
    knife = inv:AddItem("Base.KitchenKnife")
    p:setPrimaryHandItem(hammer)
    p:setSecondaryHandItem(knife)
    local cw = ZeD_CharacterWindow.getWindow()
    if cw and cw:isVisible() then was.pair = true; ZeD_CharacterWindow.toggleBothPaired(pn) end   -- the belt in plain sight first
    pcall(function() Mouse.setXY(20, 20) end)
end)
for _, c in ipairs({ { 1, 1, "full" }, { 0.7, 0.45, "70_45" }, { 0.15, 0.15, "15" } }) do
    step(10, function() setCond(hammer, c[1]); setCond(knife, c[2]) end)
    step(30, function()
        local hb = handBoxes()
        local h = hud()
        say("belt at " .. (h and (h:getAbsoluteX() .. "," .. h:getAbsoluteY()) or "?") .. ", hands: " ..
            table.concat((function() local t = {} for _, b in ipairs(hb) do t[#t + 1] = b.which .. " " .. b.x .. "," .. b.y .. " " .. b.w end return t end)(), " | "))
        check(#hb == 2, c[3] .. ": both hands on the belt")
        check(math.abs(ZeD.Belt.cond(hammer) - c[1]) < 0.06 and math.abs(ZeD.Belt.cond(knife) - c[2]) < 0.06,
            c[3] .. ": the conditions read " .. string.format("%.2f / %.2f", ZeD.Belt.cond(hammer), ZeD.Belt.cond(knife)))
        shot("belt_" .. c[3])
    end)
end

step(10, function()
    local cw = ZeD_CharacterWindow.getWindow()
    if was.pair and not (cw and cw:isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end   -- the windows back, as they were
    p:setPrimaryHandItem(was.p1)
    p:setSecondaryHandItem(was.p2)
    if hammer then inv:Remove(hammer) end
    if knife then inv:Remove(knife) end
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
