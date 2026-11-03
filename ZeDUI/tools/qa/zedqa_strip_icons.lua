-- ZeDUI/tools/qa/zedqa_strip_icons.lua  (Nov 2 2026, QA; punch list 76, no letters in the container strips)
-- In game at 4K. A pickup spawned beside the character (dash19's way: a ready car, the key, then seated). Seated, both
-- windows open: every World window container entry (the truck bed, the glove box, the seats, the floor) has a picture
-- of its own or the game's box (the strip draws entry.texture or ZeD.genericContainerTex), and the car's own containers
-- have the game's car pictures (their own texture); the same for the Character window's strip. Pictures of both
-- strips. The car and key are taken away. grep "ZEDQA sti"; shots zqa_sti_*.png.
if ZEDQA_HOME then ZEDQA_HOME("sti") end
local function say(s) print("ZEDQA sti " .. tostring(s)) end
local p = getPlayer()
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_sti_" .. n .. ".png") end) end
local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
if getGameSpeed() == 0 then setGameSpeed(1) end
local cur, curKey, pending
local OFFS = { { 5, 2 }, { 5, -3 }, { -5, 2 }, { 2, 5 }, { -4, -4 }, { 6, 6 }, { -6, 0 } }
local tries = 0
local function carReady(v)
    local sq, chunk, phys = nil, nil, false
    pcall(function() sq = v:getSquare() end)
    pcall(function() chunk = sq and sq:getChunk() end)
    pcall(function() phys = v:isPhysicsActive() end)
    return sq ~= nil and chunk ~= nil and phys == true
end
local function spawn()
    while tries < #OFFS do
        tries = tries + 1
        local o = OFFS[tries]
        local sq = getCell():getGridSquare(math.floor(p:getX()) + o[1], math.floor(p:getY()) + o[2], math.floor(p:getZ()))
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and not sq:HasTree() and not sq:getVehicleContainer() end) end
        if free then local v = addVehicleDebug("Base.PickUpTruck", IsoDirections.N, nil, sq); if v then cur = v; return true end end
    end
    return false
end
local function entries(win)
    local out = {}
    for i, c in ipairs((win and win._containers) or {}) do
        local typ = "?"; pcall(function() typ = tostring(c.inventory and c.inventory:getType()) end)
        out[#out + 1] = { i = i, name = tostring(c.name), typ = typ, own = c.texture ~= nil, src = tostring(c.sourceType) }
    end
    return out
end

local Q, qi = {}, 1
local function step(k, fn) Q[#Q + 1] = { n = k, fn = fn } end
local function waitFor(k, max, cond, fn) Q[#Q + 1] = { n = k, fn = fn, cond = cond, max = max } end
step(30, function()
    check(ZeD.genericContainerTex and ZeD.genericContainerTex() ~= nil, "76: the game's box picture is found (ZeD.genericContainerTex)")
    if not spawn() then say("ERR no free square for the pickup") end
end)
waitFor(5, 300, function() return cur == nil or carReady(cur) end, function()
    if not cur then return end
    pcall(function() cur:repair() end)
    pcall(function() curKey = p:getInventory():AddItem(cur:createVehicleKey()) end)
    cur:enter(0, p); triggerEvent("OnEnterVehicle", p)
    say("seated " .. tostring(p:getVehicle() ~= nil))
end)
step(30, function() if not (CW.isOpen() and WW.isOpen()) then CW.toggleBothPaired(0) end end)
step(60, function()
    local w = WW.getWindow()
    local list = entries(w)
    local carOwn, carAll, noPic = 0, 0, {}
    for _, e in ipairs(list) do
        say(string.format("World strip %d: %s (%s, %s) own picture %s", e.i, e.name, e.typ, e.src, tostring(e.own)))
        if e.src == "vehicle" then carAll = carAll + 1; if e.own then carOwn = carOwn + 1 end end
        if not e.own then noPic[#noPic + 1] = e.name end
    end
    check(carAll >= 3, "76: seated in the pickup, the World strip lists its containers (" .. carAll .. ")")
    check(carAll > 0 and carOwn == carAll, "76: every car container has the game's own picture (" .. carOwn .. " of " .. carAll .. ")")
    say("76: entries drawn with the game's box (no picture of their own): " .. (#noPic > 0 and table.concat(noPic, ", ") or "none"))
    local c = CW.getWindow()
    for _, e in ipairs(entries(c)) do say(string.format("Character strip %d: %s (%s) own picture %s", e.i, e.name, e.typ, tostring(e.own))) end
    shot("seated")
end)
step(10, function()
    local v = p:getVehicle(); if v then pcall(function() v:exit(p) end); triggerEvent("OnExitVehicle", p) end
    if curKey then pcall(function() p:getInventory():Remove(curKey) end) end
    pending = cur; cur = nil
end)
step(30, function()
    if pending and p:getVehicle() ~= pending then pcall(function() pending:permanentlyRemove() end) end
    if CW.isOpen() then CW.toggleBothPaired(0) end
    if fails == 0 then say("summary: all " .. passes .. " PASS") else say("summary: " .. fails .. " of " .. (passes + fails) .. " checks FAIL") end
    say("DONE")
end)

local wait, waited = nil, 0
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    if s.cond then
        waited = waited + 1
        if not s.cond() and waited < (s.max or 100) then wait = 1; return end
        waited = 0
    end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
