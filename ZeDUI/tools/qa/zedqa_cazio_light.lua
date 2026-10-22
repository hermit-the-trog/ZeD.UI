-- ZeDUI/tools/qa/zedqa_cazio_light.lua  (Oct 21 2026)
-- In game on the ZeD-QA save: the CaZio LIGHT (a tiny bulb at the display's left edge).
--   corner mode: each CaZio (digital black, gold; classic black, gold) by day and at night, its LIGHT pusher
--   clicked through the watch's own mouse handler; the light goes out after about three seconds;
--   belt mode: the mini watch lit at night through the belt's controller path (Y on the watch box);
--   the Rollex has no light (a stray press does nothing).
-- Puts back the player's own watch, the time of day and the watch option. Screenshots zqa_cl_*.png.
-- grep "ZEDQA czl".
local p = getPlayer(); local W = ZeD.Watch; local gt = getGameTime()
local function say(s) print("ZEDQA czl " .. tostring(s)) end   -- (Oct 22 2026: was "cl", which is the context-list script's tag, so the runner never saw this DONE)
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local function shot(name) pcall(function() getCore():TakeFullScreenshot("zqa_cl_" .. name .. ".png") end) end
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
        if not it then say("FAIL could not make " .. name); return nil end
        inv:AddItem(it); made[name] = it
    end
    p:setWornItem(ownLoc, it)
    return it
end
local function pressLight(tag)
    local h = hitOf("light")
    if not h then say("FAIL " .. tag .. ": no LIGHT control (hits)"); return end
    inst():onMouseDown(h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2))   -- the watch's own mouse handler
end

at(5, function()
    local worn = p:getWornItems()
    for i = 0, worn:size() - 1 do
        local wi = worn:get(i); local it = wi and wi:getItem()
        if it and instanceof(it, "AlarmClockClothing") then own = it; ownLoc = wi:getLocation() end
    end
    if not ownLoc then
        local t = mk("Base.WristWatch_Left_DigitalBlack")
        ownLoc = t and t:getBodyLocation()
    end
    say("own watch " .. tostring(own and own:getFullType()) .. " at " .. tostring(ownLoc))
    setGameSpeed(1)
    if placeOpt then placeOpt:setValue(2) end   -- Corner: the full plate
    gt:setTimeOfDay(10.97)
end)

local n = 30
for _, name in ipairs({ "DigitalBlack", "DigitalDress", "ClassicBlack", "ClassicGold" }) do
    at(n, function() gt:setTimeOfDay(10.97); wear(name) end)
    at(n + 20, function() say(name .. " plate " .. tostring(inst()._def and inst()._def.plate) .. " light at " ..
        tostring(hitOf("light") and (hitOf("light").x .. "," .. hitOf("light").y)) .. " " .. flags()); shot("day_" .. name) end)
    at(n + 25, function() pressLight(name .. " day") end)
    at(n + 40, function()
        local s = st()
        say(name .. " day pressed: " .. flags() .. ((s.bulb and not s.dark and not s.lit) and "" or "  ERR expected the bulb by day"))
        shot("daylit_" .. name)
    end)
    at(n + 45, function() inst()._litUntil = 0; gt:setTimeOfDay(23.5) end)
    at(n + 65, function() say(name .. " night: " .. flags()); shot("night_" .. name) end)
    at(n + 70, function() pressLight(name .. " night") end)
    at(n + 85, function()
        local s = st()
        say(name .. " night pressed: " .. flags() .. ((s.bulb and s.dark and not s.lit) and "" or "  ERR expected the bulb over the night"))
        shot("nightlit_" .. name)
    end)
    n = n + 100
end
-- the light goes out on its own (W.LIGHT_MS of real time)
at(n, function() wear("DigitalBlack") end)
at(n + 10, function() pressLight("timeout"); say("timer pressed at " .. getTimestampMs()) end)
local tOut = nil
at(n + 15, function()
    tOut = function()
        local s = st()
        if s and not s.bulb then say("light out after " .. (getTimestampMs() - (inst()._litUntil - W.LIGHT_MS)) .. " ms; " .. flags()); Events.OnRenderTick.Remove(tOut) end
    end
    Events.OnRenderTick.Add(tOut)
end)
n = n + 400
-- the Rollex: no light
at(n, function() wear("Expensive") end)
at(n + 15, function()
    say("Expensive light control " .. tostring(hitOf("light") ~= nil) .. (hitOf("light") and "  ERR" or ""))
    inst():_act("light")
end)
at(n + 25, function() say("Expensive after a stray light press: " .. flags() .. ((st().lit or st().bulb) and "  ERR" or "")) end)
n = n + 40
-- the belt: the mini watch lit at night through the controller's Y on the watch box
at(n, function() if placeOpt then placeOpt:setValue(1) end; W.togglePop(false); wear("DigitalBlack") end)
at(n + 30, function()
    local hud = ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD()
    local idx = nil
    for i, b in ipairs(hud and hud._boxes or {}) do if b.kind == "watch" then idx = i end end
    say("belt watch box " .. tostring(idx))
    shot("belt_night")
    if idx then
        hud._gp = { idx = idx, inList = false, row = 1, list = {} }
        hud:onJoypadDown(Joypad.YButton)
        hud._gp = nil
    end
end)
at(n + 45, function()
    local m = W.miniState(p, made.DigitalBlack)
    say("belt mini after Y: lit=" .. tostring(m.lit) .. " night=" .. tostring(m.night) .. " dark=" .. tostring(m.dark) ..
        ((m.lit and m.night and not m.dark) and "" or "  ERR expected the mini lit over the night"))
    shot("belt_nightlit")
end)
at(n + 50, function() inst()._litUntil = 0; gt:setTimeOfDay(10.97) end)
at(n + 70, function() shot("belt_day") end)
at(n + 72, function()
    local hud = ZeD.Belt.getHUD()
    for i, b in ipairs(hud._boxes or {}) do if b.kind == "watch" then hud._gp = { idx = i, inList = false, row = 1, list = {} } end end
    hud:onJoypadDown(Joypad.YButton); hud._gp = nil
end)
at(n + 85, function() shot("belt_daylit") end)
n = n + 100
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
    if tOut then Events.OnRenderTick.Remove(tOut) end
    say("restored own watch " .. tostring(own and own:getFullType()))
    say("DONE")
end)

local k, i = 0, 1
local function tick()
    k = k + 1
    while steps[i] and steps[i].n <= k do local ok, e = pcall(steps[i].f); if not ok then say("step error " .. tostring(e)) end; i = i + 1 end
    if not steps[i] then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
say("start")
