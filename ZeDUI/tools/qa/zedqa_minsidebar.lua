-- ZeDUI/tools/qa/zedqa_minsidebar.lua  (tag msb): Minimal Sidebar (MinimalSidebar, Workshop 3642084851) with ZeD last, in game.
-- ZeD's belt follows the mod's fade and its options (ModSupport/MinimalSidebar.lua, ZeD.Belt.addAlpha):
--   0. the mod is on, its options are there, ZeD's file answered and the belt has the alpha provider
--   1. the pointer away: the strap, the buckle and the slots fade out; the hand that holds something stays; the empty hand
--      fades; the Messages note stays. Picture hidden.
--   2. the pointer on the belt: everything is back. Picture shown. The pointer 30 design units above the belt (inside the
--      margin): shown. 80 above (outside): faded again.
--   3. Animation Speed: 0.5x fades slowly, 5.0x in a frame or two (frames counted from the pointer leaving)
--   4. Enable Mod off: the belt is drawn as it is (nothing faded, the real element on the belt). Picture.
--   PUT BACK: the options as found, the items, the belt reads the real cursor again.
-- By hand (the real mouse and the pad are the desktop's; here the belt is told where the pointer is): a controller on the belt keeps it shown; a menu open from a slot
-- keeps it shown; a slot dragged off the belt keeps it shown; the Messages note's bubbles still come from the note.
-- grep "ZEDQA msb"; shots zqa_msb_*.png.
local function say(s) print("ZEDQA msb " .. tostring(s)) end
local p = getPlayer()
local fails = 0
local function check(ok, what)
    if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_msb_" .. n .. ".png") end) end
local CW, WW, B = ZeD_CharacterWindow, ZeD_WorldWindow, ZeD.Belt
if not (p and CW and B) then say("ERR ZeD's belt or windows are not loaded"); say("DONE"); return end

local Q, qi, waitT, tries = {}, 1, nil, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function untilDo(n, max, fn, what) Q[#Q + 1] = { n = n, fn = fn, tries = max, what = what } end

local inv = p:getInventory()
local added, attached = {}, {}
local function give(ft)
    local ok, it = pcall(function() return inv:AddItem(ft) end)
    if ok and it then added[#added + 1] = it; return it end
    say("note: " .. ft .. " could not be added")
    return nil
end
local function hud() return B.getHUD and B.getHUD(0) or nil end
local function S() return ZeD.ModSupport and ZeD.ModSupport.MinimalSidebar end
local function st() local s = S(); return s and s.state and s.state[0] or nil end
local function active()
    local t, list = {}, getActivatedMods()
    for i = 0, list:size() - 1 do t[(tostring(list:get(i)):gsub("^\\", ""))] = i end
    return t
end
-- the mod's options, the way the mod's own file reads them
local function opt(id)
    local o = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("MinimalSideBar")
    return o and o:getOption(id) or nil
end
local was = {}
local function setOpt(id, v)
    local o = opt(id)
    if not o then return false end
    if was[id] == nil then was[id] = o:getValue() end
    o:setValue(v)
    return true
end
-- The pointer: Mouse.setXY does not hold (the game reads the desktop cursor again every frame), so the belt is told
-- where the pointer is, as zedqa_belt_ammo.lua does: its getMouseX / getMouseY answer a place relative to the belt.
-- Away is far outside the margin. pointerOff gives the belt back the real cursor.
local pointed = nil
local function pointer(rx, ry)
    local h = hud()
    if not h then return end
    pointed = h
    h.getMouseX = function() return rx end
    h.getMouseY = function() return ry end
end
local function pointerOff()
    if pointed then pointed.getMouseX, pointed.getMouseY = nil, nil; pointed = nil end
end
local function park() pointer(-5000, -5000) end
local function onBelt()
    local h = hud()
    if h then pointer(h:getWidth() / 2, h:getHeight() / 2) end
end
local function above(units)
    local h = hud()
    if h then pointer(h:getWidth() / 2, -ZeD.T.px(units)) end
end
local function slotAlpha() local s, h = S(), hud(); return s and h and s.alpha(h, "slot", nil) or nil end
local function handAlpha(which) local s, h = S(), hud(); return s and h and s.alpha(h, "hand", { which = which }) or nil end
local function lampAlpha() local s, h = S(), hud(); return s and h and s.alpha(h, "lamp", nil) end

-- 0. the mod, its options, ZeD's file
step(5, function()
    local act = active()
    check(act.MinimalSidebar ~= nil, "Minimal Sidebar is on in this game")
    check(type(S()) == "table", "ZeD's ModSupport file answered (ZeD.ModSupport.MinimalSidebar)")
    check(type(PZAPI) == "table" and opt("EnableMinimalSidebar") ~= nil and opt("AnimationSpeed") ~= nil and opt("ShowHeartOnPulse") ~= nil,
        "the mod's three options are in PZAPI.ModOptions (EnableMinimalSidebar, ShowHeartOnPulse, AnimationSpeed)")
    check(#B._alphas >= 1, "the belt has an alpha provider")
    check(hud() ~= nil, "the belt is there")
    say("options as found: enable=" .. tostring(opt("EnableMinimalSidebar") and opt("EnableMinimalSidebar"):getValue())
        .. " heart=" .. tostring(opt("ShowHeartOnPulse") and opt("ShowHeartOnPulse"):getValue())
        .. " speed index=" .. tostring(opt("AnimationSpeed") and opt("AnimationSpeed"):getValue()))
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if CW.isOpen() then CW.toggleBothPaired(0) end
    if WW and WW.isOpen and WW.isOpen() then WW.toggleBothPaired(0) end
    setOpt("EnableMinimalSidebar", true)
    setOpt("AnimationSpeed", 4)     -- 2.0x: quick enough to wait for
    -- an axe in the main hand, a knife on the belt, the off hand empty
    local axe, knife = give("Base.Axe"), give("Base.HuntingKnife")
    if axe then pcall(function() p:setPrimaryHandItem(axe) end) end
    if knife then
        local hb = B.hotbar(0)
        if hb and hb.availableSlot then
            for i = 1, #hb.availableSlot do
                if hb.attachedItems[i] == nil and B.fits(hb, i, knife) and B.attach(0, knife, i) then attached[#attached + 1] = knife; break end
            end
        end
    end
    pcall(function() p:setSecondaryHandItem(nil) end)
    onBelt()
end)
untilDo(20, 60, function() local s = st(); return s ~= nil and s.fade > 0.98 end, "the belt starts shown with the pointer on it")

-- 1. the pointer away
step(5, park)
untilDo(20, 60, function() local s = st(); return s ~= nil and s.fade < 0.02 end, "the pointer away: the fade runs out")
step(30, function()
    shot("hidden")
    check(slotAlpha() == 0, "the slots and the strap are at 0 (" .. tostring(slotAlpha()) .. ")")
    check(handAlpha("p") ~= nil and handAlpha("p") > 0.98, "the hand that holds the axe stays (" .. tostring(handAlpha("p")) .. ")")
    check(handAlpha("s") ~= nil and handAlpha("s") < 0.02, "the empty hand is faded (" .. tostring(handAlpha("s")) .. ")")
    check(lampAlpha() == nil, "the Messages note is not faded")
    local h = hud()
    check(h ~= nil and h:getIsVisible(), "the belt element is still on the screen")
    local jo = h and h.javaObject
    local px = false
    if jo then pcall(function() px = rawget(h, "_fade") ~= nil and rawget(h, "_fade").on == true end) end
    check(not px, "the belt's real element is back after the frame (no stand-in left on)")
end)

-- 2. the pointer on the belt, and the margin
step(5, function() onBelt() end)
untilDo(20, 60, function() local s = st(); return s ~= nil and s.fade > 0.98 end, "the pointer on the belt: it comes back")
step(30, function()
    shot("shown")
    check(slotAlpha() == 1 and handAlpha("s") == 1, "the slots and both hands are back")
    above(30)
end)
step(60, function()
    local s = st()
    check(s and s.fade > 0.98, "the pointer 30 units above the belt (inside the margin): still shown (" .. tostring(s and s.fade) .. ")")
    above(80)
end)
untilDo(20, 60, function() local s = st(); return s ~= nil and s.fade < 0.02 end, "the pointer 80 units above the belt (outside the margin): faded again")

-- 3. Animation Speed: render frames from the pointer leaving to the fade passing a half
local counting, frames, fastFrames, slowFrames = false, 0, nil, nil
local function counter()
    if not counting then return end
    frames = frames + 1
    local s = st()
    if s and s.fade < 0.5 then counting = false end
end
Events.OnRenderTick.Add(counter)
local function measure(index, store)
    step(5, function() setOpt("AnimationSpeed", index); onBelt() end)
    untilDo(20, 90, function() local s = st(); return s ~= nil and s.fade > 0.98 end, "speed item " .. index .. ": shown again")
    step(10, function() frames = 0; counting = true; park() end)
    untilDo(5, 200, function() return counting == false end, "speed item " .. index .. ": the fade passes a half")
    step(2, function() store(frames) end)
end
measure(1, function(n) slowFrames = n end)
measure(10, function(n) fastFrames = n end)
step(5, function()
    say("frames to half: 0.5x = " .. tostring(slowFrames) .. ", 5.0x = " .. tostring(fastFrames))
    check(slowFrames ~= nil and slowFrames >= 8, "0.5x fades slowly (about 14 frames; counted " .. tostring(slowFrames) .. ")")
    -- (OnRenderTick counts a couple of frames before the belt first draws the parked pointer, so the fast
    -- speed is judged against the slow one: at least three times quicker, and within a few frames)
    check(fastFrames ~= nil and slowFrames ~= nil and fastFrames <= 5 and fastFrames * 3 <= slowFrames,
        "5.0x fades within a few frames, at least 3x faster than 0.5x (counted " .. tostring(fastFrames) .. " vs " .. tostring(slowFrames) .. ")")
    setOpt("AnimationSpeed", 4)
end)

-- 4. Enable Mod off
step(5, function() setOpt("EnableMinimalSidebar", false); park() end)
step(60, function()
    shot("off")
    local s = st()
    check(s ~= nil and s.on == false, "Enable Mod off: ZeD's fade is off")
    check(slotAlpha() == nil and handAlpha("s") == nil, "Enable Mod off: no part is faded")
    setOpt("EnableMinimalSidebar", true)
end)
untilDo(20, 90, function() local s = st(); return s ~= nil and s.on == true and s.fade < 0.02 end, "Enable Mod on again: the belt fades with the pointer away")

-- put back
step(10, function()
    Events.OnRenderTick.Remove(counter)
    for id, v in pairs(was) do
        local o = opt(id)
        if o then o:setValue(v) end
    end
    pointerOff()
    for _, it in ipairs(attached) do pcall(B.detach, 0, it) end
    pcall(function() p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end)
    for _, it in ipairs(added) do pcall(function() inv:Remove(it) end) end
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

-- a step's n is in 60ths of a second (wall clock; OnRenderTick runs while paused)
local function tick()
    local s = Q[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    waitT = waitT or (now + s.n * 1000 / 60)
    if now < waitT then return end
    waitT = nil
    local ok, res = pcall(s.fn)
    if not ok then
        fails = fails + 1; say("ERR step " .. qi .. ": " .. tostring(res)); qi = qi + 1; tries = 0
    elseif s.tries and res ~= true then
        tries = tries + 1
        if tries >= s.tries then fails = fails + 1; say("FAIL timed out: " .. tostring(s.what)); qi = qi + 1; tries = 0 end
    else
        if s.what then say("PASS " .. s.what) end
        qi = qi + 1; tries = 0
    end
end
Events.OnRenderTick.Add(tick)
say("start")
