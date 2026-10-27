-- ZeDUI/tools/qa/zedqa_r3_fixes.lua  (Oct 27 2026, the round 3 ZeD bugs, fixed)
-- With compat_r3_fixes_mods.txt (Starlit Library + Show Sowing Season, More Item Information, Smart Radial
-- Menu, Brita's belt slots, True Music Jukebox, NeatUI Framework + Neat Rocco's UI):
--   1 the item tooltip keeps other mods' lines: ZeD's tooltip is as tall as safe mode's (seed packet, shirt)
--   3 Smart Radial Menu's own wheel opens with the engine's RadialMenu under it, no error
--   5 Brita's belt slots read the mod's own names, cut to the box
--   4 (zedqa_quick_chords.lua in the manifest) and 6 (zedqa_messages.lua) run after this script
-- grep "ZEDQA fix". Pictures zqa_fix_*.png.
local function say(s) print("ZEDQA fix " .. tostring(s)) end
local p = getPlayer()
local inv = p:getInventory()
local function give(t) local ok, it = pcall(function() return inv:AddItem(t) end); return ok and it or nil end
local fails = 0
local function check(name, ok, detail)
    if not ok then fails = fails + 1 end
    say((ok and "PASS " or "ERR ") .. name .. (detail and (" (" .. tostring(detail) .. ")") or ""))
end

local tip
local function showTip(item)
    if tip then pcall(function() tip:removeFromUIManager() end); tip = nil end
    if not item then return end
    tip = ISToolTipInv:new(item)
    tip:initialise(); tip:addToUIManager(); tip:setVisible(true)
    tip:setOwner(nil); tip:setCharacter(p)
    tip.followMouse = false; tip:setX(900); tip:setY(300)
    tip.anchorBottomLeft = nil
end
local function tipSize() return tip and math.floor(tip:getHeight()) or -1, tip and math.floor(tip:getWidth()) or -1 end
local function hideTip() if tip then pcall(function() tip:removeFromUIManager() end); tip = nil end end
local safeOpt = ZeD.Settings and ZeD.Settings.safeModeOption
local safeWas = safeOpt and safeOpt:getValue()
local function safe(on) if safeOpt then safeOpt:setValue(on and 2 or 1); pcall(function() ZeD.Safe.reread() end) end end

local Q = {}
local function step(fn, wait) Q[#Q + 1] = { fn = fn, wait = wait or 20 } end
local function shot(name) pcall(function() getCore():TakeFullScreenshot("zqa_fix_" .. name .. ".png") end) end

local seed, shirt
local sizes = {}
step(function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    p:setGodMod(true)
    seed = give("Base.CarrotBagSeed2"); shirt = give("Base.Shirt_FormalWhite")
end)
for _, pair in ipairs({ { "seed", function() return seed end }, { "shirt", function() return shirt end } }) do
    local k = pair[1]
    step(function() showTip(pair[2]()) end, 15)
    step(function() shot("tip_" .. k .. "_zed"); local h, w = tipSize(); sizes[k .. "zed"] = h; say("tip " .. k .. " zed " .. w .. "x" .. h); hideTip(); safe(true) end, 15)
    step(function() showTip(pair[2]()) end, 15)
    step(function()
        shot("tip_" .. k .. "_safe")
        local h, w = tipSize(); say("tip " .. k .. " safe " .. w .. "x" .. h); hideTip(); safe(false)
        if safeOpt and safeWas then safeOpt:setValue(safeWas); pcall(function() ZeD.Safe.reread() end) end
        check("tooltip " .. k .. " keeps the mods' lines", math.abs((sizes[k .. "zed"] or 0) - h) <= 2, "zed " .. tostring(sizes[k .. "zed"]) .. ", safe " .. h)
    end, 30)
end
-- Smart Radial Menu
step(function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    local ok, e = pcall(function() SRMRadialMenu.showRadialMenu(p) end)
    check("smart radial menu opens", ok and SRMRadialMenu ~= nil, e)
end, 60)
step(function()
    shot("srm")
    local root = SRMRadialMenu and SRMRadialMenu.SRMRootMenu and SRMRadialMenu.SRMRootMenu[0]
    local jo = root and root.javaObject
    local okIdx = jo and pcall(function() return jo:getSliceIndexFromMouse(0, 0) end)
    check("its wheel is the engine's", okIdx and root._zed == nil, tostring(root and root.Type))
    pcall(function() root:undisplay() end)
    -- the game's own wheels stay ZeD's
    local m = getPlayerRadialMenu(0)
    say("player wheel: ZeD's " .. tostring(m and m._zed))
end, 20)
-- the belt with Brita's slots
local names = {}
step(function()
    for _, t in ipairs({ "BritaBeltFront", "BritaBeltBack" }) do
        local s = ZeD.Belt and ZeD.Belt.shortName and ZeD.Belt.shortName(t, { name = getTextOrNull("IGUI_BritaBeltCarry" .. t:sub(10)) })
        names[#names + 1] = tostring(s)
    end
    say("belt names: " .. table.concat(names, ", "))
    check("belt uses the mod's names", not tostring(names[1]):find("^BRITA") and not tostring(names[1]):find("^BritaBelt"), names[1])
    give("Base.HuntingRifle")
end, 40)
step(function() shot("belt") end, 10)
step(function() say("errors " .. fails); say("DONE") end, 1)

local i, wait = 1, 30
local function tick()
    if wait > 0 then wait = wait - 1; return end
    local s = Q[i]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local ok, e = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. i .. ": " .. tostring(e)) end
    wait = s.wait
    i = i + 1
end
Events.OnRenderTick.Add(tick)
say("start")
