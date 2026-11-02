-- ZeDUI/tools/qa/zedqa_simple_belt.lua  (Nov 2 2026, QA; punch list 56, the Simple belt)
-- In game. ZeD setup's "Belt: Full | Simple" (ZeD.Settings.beltStyleOption). Full first (strap and buckle there), then
-- Simple: no strap, buckle, runs or closure; both hands; every slot of the hotbar as a box, in key order, 6 design units
-- apart; the belt centred on the screen; a pistol in hand shows the ammo tab; a worn watch on the left wrist and then the
-- right shows the watch box; the Messages lamp box; a knife attached to a free slot (the drag's own call, B.attach) and
-- taken off (B.detach); slot 1's key (B.activate) puts its item in hand; moodles at Bottom sit above the belt.
-- Pictures of Full and Simple. Everything is put back. grep "ZEDQA sbl"; shots zqa_sbl_*.png.
local function say(s) print("ZEDQA sbl " .. tostring(s)) end
local p = getPlayer()
local B = ZeD and ZeD.Belt
local opt = ZeD and ZeD.Settings and ZeD.Settings.beltStyleOption
if not (p and B and opt and B.getHUD and B.getHUD()) then say("ERR the belt or its Simple option is not loaded"); say("DONE"); return end
local hud = B.getHUD()
local T = ZeD.T
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_sbl_" .. n .. "_" .. sw .. "x" .. sh .. ".png") end) end
local styleWas = opt:getValue()
local MO, moodOpt = ZeD.Moodles, ZeD.Settings.moodlePlaceOption
local moodWas = moodOpt and moodOpt:getValue()
local inv = p:getInventory()
local given = {}
local function give(ft) local it = inv:AddItem(ft); if it then given[#given + 1] = it end; return it end
local primWas, secWas = p:getPrimaryHandItem(), p:getSecondaryHandItem()
local godWas = p:isGodMod()

local function boxes(kind)
    local t = {}
    for _, b in ipairs(hud._boxes or {}) do if b.kind == kind then t[#t + 1] = b end end
    return t
end
local function summary(label)
    local s = boxes("slot")
    local xs = {}
    for _, b in ipairs(s) do xs[#xs + 1] = b.i .. "@" .. math.floor(b.x) end
    say(label .. ": belt " .. math.floor(hud:getX()) .. "," .. math.floor(hud:getY()) .. " " .. math.floor(hud:getWidth()) .. "x" .. math.floor(hud:getHeight())
        .. " | hands " .. #boxes("hand") .. " | slots " .. #s .. " (" .. table.concat(xs, " ") .. ") of " .. #B.slots(0)
        .. " | ammo " .. #boxes("ammo") .. " | watch " .. #boxes("watch") .. " | lamp " .. #boxes("lamp")
        .. " | strap " .. tostring(hud._strap ~= nil) .. " buckle " .. tostring(hud._buckle ~= nil))
end

local Q = {}
local function step(k, fn) Q[#Q + 1] = { n = k, fn = fn } end
step(5, function()
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
    opt:setValue(1)
end)
step(40, function()
    summary("Full")
    check(hud._strap ~= nil and hud._buckle ~= nil, "Full: the strap and buckle are drawn")
    shot("full")
    opt:setValue(2)
end)
step(40, function()
    summary("Simple")
    check(B.simple() == true, "Simple is on (B.simple)")
    check(hud._strap == nil and hud._buckle == nil and hud._runs == nil and hud._closure == nil, "Simple: no strap, buckle, runs or closure")
    check(#boxes("hand") == 2, "Simple: both hands (" .. #boxes("hand") .. ")")
    local s = boxes("slot")
    check(#s == #B.slots(0), "Simple: a box for every slot (" .. #s .. " of " .. #B.slots(0) .. ")")
    local order, gapOk, gaps = true, true, {}
    for k = 2, #s do
        if s[k].i <= s[k - 1].i or s[k].x <= s[k - 1].x then order = false end
        local g = s[k].x - (s[k - 1].x + s[k - 1].w)
        gaps[#gaps + 1] = math.floor(g)
    end
    local want = T.px(6)
    for _, g in ipairs(gaps) do if math.abs(g - want) > 1.5 then gapOk = false end end
    check(order, "Simple: the slots run in key order, left to right")
    if #s > 1 then check(gapOk, "Simple: slots " .. want .. " px apart (6 units): " .. table.concat(gaps, ",")) end
    local mid = hud:getX() + hud:getWidth() / 2
    check(math.abs(mid - sw / 2) <= 2, "Simple: the belt is centred (" .. math.floor(mid) .. " of " .. math.floor(sw / 2) .. ")")
    check(#boxes("lamp") >= 1, "Simple: the Messages lamp is there")
    shot("simple")
end)
-- a pistol in hand: the ammo tab
step(5, function()
    local gun = give("Base.Pistol")
    if gun then p:setPrimaryHandItem(gun) end
end)
step(40, function()
    summary("Simple, pistol in hand")
    check(#boxes("ammo") == 1, "Simple: a pistol in hand shows the ammo tab")
    shot("simple_pistol")
    p:setPrimaryHandItem(primWas)
end)
-- a watch on each wrist
step(5, function()
    local w = give("Base.WristWatch_Left_DigitalBlack")
    if w then p:setWornItem(w:getBodyLocation(), w) end
end)
step(40, function()
    local wb = boxes("watch")[1]
    summary("Simple, watch left")
    check(wb ~= nil, "Simple: a watch on the left wrist shows on the belt (" .. tostring(wb and wb.wrist) .. ")")
    shot("simple_watch_left")
    local cur = given[#given]
    pcall(function() p:removeWornItem(cur) end)
    local w2 = give("Base.WristWatch_Right_DigitalBlack")
    if w2 then p:setWornItem(w2:getBodyLocation(), w2) end
end)
step(40, function()
    local wb = boxes("watch")[1]
    summary("Simple, watch right")
    check(wb ~= nil, "Simple: a watch on the right wrist shows on the belt (" .. tostring(wb and wb.wrist) .. ")")
    shot("simple_watch_right")
    pcall(function() p:removeWornItem(given[#given]) end)
end)
-- drag onto a free slot and off, then the slot's key
local att
step(5, function()
    local hb = B.hotbar(0)
    local knife = give("Base.HuntingKnife")
    for _, s in ipairs(B.slots(0)) do
        if not s.item and knife and B.fits(hb, s.i, knife) then
            if B.attach(0, knife, s.i) then att = { item = knife, i = s.i } end
            break
        end
    end
    say("knife onto slot " .. tostring(att and att.i))
end)
step(40, function()
    if not check(att ~= nil, "Simple: a knife goes onto a free slot (the drag's call)") then return end
    local s = B.slots(0)[att.i]
    check(s and s.item == att.item, "Simple: slot " .. att.i .. " holds the knife")
    summary("Simple, knife on")
    B.activate(0, att.i)
end)
step(120, function()
    if not att then return end
    check(p:getPrimaryHandItem() == att.item, "Simple: slot " .. att.i .. "'s key puts the knife in hand (" .. tostring(p:getPrimaryHandItem()) .. ")")
    p:setPrimaryHandItem(primWas); p:setSecondaryHandItem(secWas)
    B.detach(0, att.item)
end)
step(40, function()
    if not att then return end
    local s = B.slots(0)[att.i]
    check(s and s.item == nil, "Simple: the knife comes off the slot (the drag out)")
end)
-- moodles at Bottom above the belt
step(5, function()
    p:setGodMod(false)
    for k, v in pairs({ HUNGER = 0.45, THIRST = 0.45, FATIGUE = 0.75 }) do pcall(function() p:getStats():set(CharacterStat[k], v) end) end
    if moodOpt then moodOpt:setValue(3) end
end)
step(60, function()
    local r = MO and MO.rect and MO.rect(0)
    say("moodles at Bottom: rect " .. tostring(r and (math.floor(r.x) .. "," .. math.floor(r.y) .. " " .. math.floor(r.w) .. "x" .. math.floor(r.h))) .. " | belt top " .. math.floor(hud:getY()))
    check(r ~= nil and r.y + r.h <= hud:getY() + 1, "Simple: the moodles at Bottom sit above the belt")
    shot("simple_moodles_bottom")
end)
step(5, function()
    if moodOpt and moodWas then moodOpt:setValue(moodWas) end
    p:setGodMod(godWas)
    for _, it in ipairs(given) do pcall(function() p:removeWornItem(it) end); pcall(function() inv:Remove(it) end) end
    p:setPrimaryHandItem(primWas); p:setSecondaryHandItem(secWas)
    opt:setValue(styleWas)
end)
step(30, function()
    summary("put back")
    say("summary: " .. passes .. " PASS, " .. fails .. " FAIL")
    say("DONE")
end)

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
