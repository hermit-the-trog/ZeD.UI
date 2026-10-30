-- ZeDUI/tools/qa/zedqa_watch_grey.lua  (Oct 29 2026)
-- In game on the ZeD-QA save: the watches' one grey screen (HANDOFF_watch_grey_20261029).
--   Every watch kind in turn through the bridge (CaZio digital black and gold, CaZio classic black and gold, Timez red,
--   Timez steel, Easy Reader, Camper, the Rollex), the full watch in the corner:
--     by day, at night, the CaZio bulb (LIGHT) by day and at night, the Timez glow (INDIGLOW) at night,
--     and while the alarm is being set (the digital's face outline, the strap seam, the grey figures).
--   Then the belt: each watch's mini by day and at night, the CaZio bulb and the Timez glow on the mini.
--   Each shot is the 4K frame (zqa_wg_<name>.png in Zomboid/Screenshots); the line "ZEDQA wgrey RECT <name> x y w h" is the
--   watch's place on it, for the cropper (tools/qa/crop_watch_grey.py), which writes the JPG crops.
-- The windows go back to their default spread first (the runner does it before every script; this one does it again).
-- Puts back the player's own watch, the time of day and the watch option. grep "ZEDQA wgrey".
local p = getPlayer(); local W = ZeD.Watch; local gt = getGameTime()
local function say(s) print("ZEDQA wgrey " .. tostring(s)) end
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local inv = p:getInventory()
local function mk(ft) if instanceItem then return instanceItem(ft) end; return InventoryItemFactory.CreateItem(ft) end
local own, ownLoc = nil, nil
local made = {}
local tod0 = gt:getTimeOfDay()
local placeOpt = ZeD.Settings and ZeD.Settings.watchPlaceOption
local placeWas = placeOpt and placeOpt:getValue()
local function inst() return W.getInstance() end
local function st() return inst()._st end
local function hitOf(id) for _, h in ipairs(inst()._hit or {}) do if h.id == id then return h end end end
local function flags() local s = st(); return "lit=" .. tostring(s.lit) .. " bulb=" .. tostring(s.bulb) .. " dark=" .. tostring(s.dark) end

-- kind, item, the key that opens the alarm setting (CaZio and Timez digitals and the CaZio classics: SET; the others: the crown)
local KINDS = {
    { "digital_black", "DigitalBlack", "set", "cazio" }, { "digital_gold", "DigitalDress", "set", "cazio" },
    { "classic_black", "ClassicBlack", "set", "cazio" }, { "classic_gold", "ClassicGold", "set", "cazio" },
    { "timez_red", "DigitalRed", "set", "timez" }, { "timez_steel", "DigitalTimez", "set", "timez" },
    { "timez_easy", "ClassicBrown", "crown", nil }, { "timez_camper", "ClassicMilitary", "crown", nil },
    { "expensive", "Expensive", "crown", nil },
}

local function rect(name, x, y, w, h)
    say(string.format("RECT %s %d %d %d %d", name, x, y, w, h))
    pcall(function() getCore():TakeFullScreenshot("zqa_wg_" .. name .. ".png") end)
end
local function shotPlate(name) local i = inst(); rect(name, i:getAbsoluteX(), i:getAbsoluteY(), i:getWidth(), i:getHeight()) end
local function miniBox()
    local hud = ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD()
    if not hud then return nil end
    for i, b in ipairs(hud._boxes or {}) do if b.kind == "watch" then return hud, b, i end end
end
local function shotMini(name)
    local hud, b = miniBox()
    if not b then say("ERR " .. name .. ": no watch box on the belt"); return end
    rect(name, hud:getAbsoluteX() + b.x, hud:getAbsoluteY() + b.y, b.w, b.h)
end
local function wear(name)
    local worn = p:getWornItems()
    local cur = {}
    for i = 0, worn:size() - 1 do
        local wi = worn:get(i); local it = wi and wi:getItem()
        if it and instanceof(it, "AlarmClockClothing") then cur[#cur + 1] = it end
    end
    for _, it in ipairs(cur) do p:removeWornItem(it) end
    local it = made[name]
    if not it then
        it = mk("Base.WristWatch_Left_" .. name)
        if not it then say("ERR could not make " .. name); return nil end
        inv:AddItem(it); made[name] = it
    end
    p:setWornItem(ownLoc, it)
    return it
end
local function pressLight()
    local h = hitOf("light")
    if not h then say("ERR no LIGHT control"); return false end
    inst():onMouseDown(h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2))   -- the watch's own mouse handler
    return true
end
local function padLight()          -- the belt's mini lit through the controller's Y on the watch box
    local hud, _, idx = miniBox()
    if not hud then return end
    hud._gp = { idx = idx, inList = false, row = 1, list = {} }
    hud:onJoypadDown(Joypad.YButton)
    hud._gp = nil
end

local DAY, NIGHT, DEEP = 10.97, 23.5, 2.25
local n = 5
at(n, function()
    local worn = p:getWornItems()
    for i = 0, worn:size() - 1 do
        local wi = worn:get(i); local it = wi and wi:getItem()
        if it and instanceof(it, "AlarmClockClothing") then own = it; ownLoc = wi:getLocation() end
    end
    if not ownLoc then local t = mk("Base.WristWatch_Left_DigitalBlack"); ownLoc = t and t:getBodyLocation() end
    say("own watch " .. tostring(own and own:getFullType()) .. " at " .. tostring(ownLoc))
    setGameSpeed(1)
    if ZeD_Window and ZeD_Window.resetLayout then pcall(ZeD_Window.resetLayout) end   -- the footer's R
    if placeOpt then placeOpt:setValue(2) end   -- Corner: the full plate
    gt:setTimeOfDay(DAY)
end)
n = 40

-- ---- the full watch in the corner
for _, k in ipairs(KINDS) do
    local kind, name, opener, brand = k[1], k[2], k[3], k[4]
    at(n, function() inst()._litUntil = 0; gt:setTimeOfDay(DAY); wear(name) end)
    at(n + 25, function()
        local i = inst()
        say(kind .. " plate " .. tostring(i._def and i._def.plate) .. " " .. i:getWidth() .. "x" .. i:getHeight() .. " " .. flags() ..
            ((i._def and i._def.plate == kind) and "" or "  ERR expected plate " .. kind))
        shotPlate("day_" .. kind)
    end)
    n = n + 50
    at(n, function() gt:setTimeOfDay(NIGHT) end)
    at(n + 25, function() say(kind .. " night " .. flags() .. (st().dark and "" or "  ERR expected dark")); shotPlate("night_" .. kind) end)
    n = n + 50
    if brand == "cazio" then
        at(n, function() pressLight() end)
        at(n + 10, function()
            say(kind .. " night bulb " .. flags() .. ((st().bulb and st().dark) and "" or "  ERR expected the bulb over the night"))
            shotPlate("nightbulb_" .. kind)
        end)
        n = n + 60
        at(n, function() inst()._litUntil = 0; gt:setTimeOfDay(DAY) end)
        at(n + 20, function() pressLight() end)
        at(n + 30, function()
            say(kind .. " day bulb " .. flags() .. ((st().bulb and not st().dark) and "" or "  ERR expected the bulb by day"))
            shotPlate("daybulb_" .. kind)
        end)
        n = n + 60
    elseif brand == "timez" then
        at(n, function() inst()._litUntil = 0; gt:setTimeOfDay(DEEP) end)
        at(n + 25, function() pressLight() end)
        at(n + 35, function()
            say(kind .. " glow " .. flags() .. (st().lit and "" or "  ERR expected lit"))
            shotPlate("glow_" .. kind)
        end)
        n = n + 70
        at(n, function() inst()._litUntil = 0 end)
    end
    -- the alarm being set (by day): SET / the crown, then + + for 01
    at(n, function() inst()._litUntil = 0; gt:setTimeOfDay(DAY) end)
    at(n + 20, function() inst():_act(opener) end)
    at(n + 30, function() inst():_act("setup"); inst():_act("setup") end)
    at(n + 45, function()
        local it = made[name]
        say(kind .. " setting open=" .. tostring(inst()._setOpen) .. " alarm " .. tostring(it:isAlarmSet()) .. " hour " .. tostring(it:getHour()) ..
            (inst()._setOpen and "" or "  ERR expected the setting open"))
        shotPlate("set_" .. kind)
    end)
    at(n + 55, function() inst():_act(opener); made[name]:setAlarmSet(false) end)
    n = n + 90
    -- a CaZio digital: the setting at night as well (grey on the night glass)
    if kind == "digital_black" or kind == "classic_black" then
        at(n, function() gt:setTimeOfDay(NIGHT) end)
        at(n + 20, function() inst():_act(opener) end)
        at(n + 30, function() inst():_act("setup") end)
        at(n + 45, function() say(kind .. " setting at night " .. flags()); shotPlate("setnight_" .. kind) end)
        at(n + 55, function() inst():_act(opener); made[name]:setAlarmSet(false); gt:setTimeOfDay(DAY) end)
        n = n + 90
    end
end

-- ---- the belt minis
at(n, function() inst()._litUntil = 0; gt:setTimeOfDay(DAY); if placeOpt then placeOpt:setValue(1) end end)   -- Belt
n = n + 40
for _, k in ipairs(KINDS) do
    local kind, name, opener, brand = k[1], k[2], k[3], k[4]
    at(n, function() gt:setTimeOfDay(DAY); wear(name) end)
    at(n + 30, function()
        local hud, b = miniBox()
        say(kind .. " mini box " .. tostring(b and (b.plate .. " " .. b.w .. "x" .. b.h)) .. (b and "" or "  ERR no mini"))
        shotMini("minyday_" .. kind)
    end)
    n = n + 50
    at(n, function() gt:setTimeOfDay(NIGHT) end)
    at(n + 30, function() shotMini("minynight_" .. kind) end)
    n = n + 50
    if brand then
        at(n, function() gt:setTimeOfDay(brand == "timez" and DEEP or NIGHT) end)
        at(n + 20, function() padLight() end)
        at(n + 30, function()
            local m = W.miniState(p, made[name])
            say(kind .. " mini lit=" .. tostring(m.lit) .. " bulb=" .. tostring(m.bulb) .. " dark=" .. tostring(m.dark))
            shotMini("minylit_" .. kind)
        end)
        n = n + 60
        at(n, function() inst()._litUntil = 0 end)
    end
end

at(n, function()
    local worn = p:getWornItems()
    local watches = {}
    for i = 0, worn:size() - 1 do
        local wi = worn:get(i); local it = wi and wi:getItem()
        if it and instanceof(it, "AlarmClockClothing") then watches[#watches + 1] = it end
    end
    for _, it in ipairs(watches) do p:removeWornItem(it) end
    for _, it in pairs(made) do inv:Remove(it) end
    if own and ownLoc then p:setWornItem(ownLoc, own) end
    gt:setTimeOfDay(tod0)
    if placeOpt and placeWas then placeOpt:setValue(placeWas) end
    say("restored own watch " .. tostring(own and own:getFullType()))
    say("DONE")
end)

local k, i = 0, 1
local function tick()
    k = k + 1
    while steps[i] and steps[i].n <= k do local ok, e = pcall(steps[i].f); if not ok then say("ERR step " .. steps[i].n .. " " .. tostring(e)) end; i = i + 1 end
    if not steps[i] then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
say("start")
