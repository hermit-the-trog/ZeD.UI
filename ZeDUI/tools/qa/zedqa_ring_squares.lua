-- ZeDUI/tools/qa/zedqa_ring_squares.lua  (Oct 24 2026)
-- Two edits the director asked for together:
--   * the hands' condition as a ring inset inside the circle ("the bar looks odd in the
--     circle. a ring slightly inset inside would be the better place for it"): a hammer in
--     the main hand and a kitchen knife in the off hand at full, 70 / 45 and 15 per cent,
--     a picture of the belt at each;
--   * ZeD setup's switch that hides the theme, accent and text squares on windows ("add
--     option in ZeD settings to hide theme/accent/text buttons on windows"): the Character
--     window's footer with the squares shown and hidden, R still there and answering.
-- The hands, the conditions and the switch are put back. grep "ZEDQA rs".
local p = getPlayer()
local pn = p:getPlayerNum()
local S = ZeD.Settings
local function say(s) print("ZEDQA rs " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_rs_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

if not (S and S.windowSquaresOption and ZeD.Belt and ZeD.Belt._ringArc) then say("ERR the new code is not loaded"); say("DONE"); return end
local was = { p1 = p:getPrimaryHandItem(), p2 = p:getSecondaryHandItem(), squares = S.windowSquaresOption:getValue() }
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
    if cw and cw:isVisible() then ZeD_CharacterWindow.toggleBothPaired(pn) end   -- the belt in plain sight first
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

-- the switch: the Character window's footer with the squares, then without
step(10, function()
    S.windowSquaresOption:setValue(2)
    local cw = ZeD_CharacterWindow.getWindow()
    if not (cw and cw:isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
end)
step(40, function()
    local cw = ZeD_CharacterWindow.getWindow()
    local r = cw and cw._themeControlRects or {}
    say("window at " .. cw:getAbsoluteX() .. "," .. cw:getAbsoluteY() .. " " .. cw:getWidth() .. "x" .. cw:getHeight())
    check(r[1] and r[2] and r[3] and r[4], "on: theme, accent, text and R squares in the footer")
    shot("squares_on")
end)
step(10, function() S.windowSquaresOption:setValue(1) end)
step(20, function()
    local cw = ZeD_CharacterWindow.getWindow()
    local r = cw and cw._themeControlRects or {}
    check(S.windowSquaresOn() == false, "off: the switch reads off")
    check(not r[1] and not r[2] and not r[3], "off: no theme, accent or text square")
    check(r[4] ~= nil and r[4].x == cw:getAbsoluteX(), "off: R stays, at the left where the theme square was")
    -- R still answers: the pointer over it lights it (the press itself is the same code as before)
    if r[4] then pcall(function() Mouse.setXY(r[4].x + math.floor(r[4].w / 2), r[4].y + math.floor(r[4].h / 2)) end) end
    shot("squares_off")
end)
-- R answering. A script cannot move the pointer of a fullscreen game (Mouse.setXY left it where
-- the runner clicked, the screen's centre: run 2026-10-24_2237), so the pointer, the button and
-- the engine's "nothing above this window" are stood in for, for this window only, a few frames:
-- what the footer's own code then does is real. A press on R is counted, not let through (it
-- would put every window back to the default spread).
local realX, realY, realDown, realReset = getMouseX, getMouseY, isMouseButtonDown, ZeD_Window.resetLayout
local at, held, resets = nil, false, 0
local function standIn(cw)
    getMouseX = function() return at and at[1] or realX() end
    getMouseY = function() return at and at[2] or realY() end
    isMouseButtonDown = function(b) if b == 0 and held then return true end return realDown(b) end
    ZeD_Window.resetLayout = function() resets = resets + 1 end
    cw.pointerOn = function() return true end
end
local function standDown(cw)
    getMouseX, getMouseY, isMouseButtonDown, ZeD_Window.resetLayout = realX, realY, realDown, realReset
    cw.pointerOn = nil
end
local function over(r) at = { r.x + math.floor(r.w / 2), r.y + math.floor(r.h / 2) } end
step(10, function()
    local cw = ZeD_CharacterWindow.getWindow()
    standIn(cw)
    over(cw._themeControlRects[4])
end)
step(5, function()
    local cw = ZeD_CharacterWindow.getWindow()
    check(cw._themeControlHover == 4, "off: the pointer over R lights R (hover " .. tostring(cw._themeControlHover) .. ")")
    held = true
end)
-- (held and let go for 15 drawn frames each: the windows' update can run less often than the
-- screen draws, and a 3-frame press went unseen, run 2026-10-24_2244)
step(15, function() held = false end)
step(15, function()
    check(resets == 1, "off: a press on R puts the windows back (" .. resets .. " press)")
    S.windowSquaresOption:setValue(2)
end)
step(10, function()
    local cw = ZeD_CharacterWindow.getWindow()
    over(cw._themeControlRects[1])
end)
step(5, function()
    local cw = ZeD_CharacterWindow.getWindow()
    check(cw._themeControlHover == 1, "on: the pointer over the theme square lights it (hover " .. tostring(cw._themeControlHover) .. ")")
    at = nil
    standDown(cw)
end)

step(10, function()
    S.windowSquaresOption:setValue(was.squares or 2)
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
