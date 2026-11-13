-- ZeDUI/tools/qa/zedqa_msc_run2.lua  (Nov 12 2026, QA 177; baseline for the Maskarad's Summer Car compatibility fix)
-- Run 2: ZeD OUT of the mod list (the QA shim's bridge only), Summer Car on, the game's own Vehicle Mechanics window.
-- A plain car on the drag strip with its key; the game's ISVehicleMenu.onMechanic. Logs when the mechanics window,
-- the open hood and the Summer Car engine window appear, both windows' x, y, width and height, the Engine part's
-- right-click menu (ui:doPartContextMenu through the bridge), what the window shows, whether it closes itself with
-- the mechanics window. grep "ZEDQA msc2"; shots zqa_msc2_*.png. Nothing is fixed here.
local function say(s) print("ZEDQA msc2 " .. tostring(s)) end
local p = getPlayer()
local pn = p:getPlayerNum()
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_msc2_" .. n .. ".png") end); say("shot " .. n) end
local function now() return getTimestampMs() end
pcall(function() p:setGodMod(true) end)
if getGameSpeed() <= 0 then setGameSpeed(1) end
-- home: the drag strip, as the prelude does
local HOME = { x = 925.5, y = 13040.5 }
if p:getVehicle() then p:getVehicle():exit(p) end
if math.abs(p:getX() - HOME.x) > 3 or math.abs(p:getY() - HOME.y) > 3 then
    p:setX(HOME.x); p:setY(HOME.y); p:setZ(0); p:setLastX(HOME.x); p:setLastY(HOME.y); p:setLastZ(0)
    say("moved to the drag strip")
end
say("ZeD loaded: " .. tostring(ZeD ~= nil) .. " (should be false) | MSC loaded " .. tostring(MSC ~= nil) .. " | screen " .. sw .. "x" .. sh)

local Q, qi, qstart = {}, 0, 0
local function add(name, fn, cap) Q[#Q + 1] = { n = name, fn = fn, cap = cap or 0 } end
local function wait(ms) local t0; add("wait " .. ms, function() t0 = t0 or now(); return now() - t0 >= ms end) end

local function findMsc()
    local out = {}
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local e = ui:get(i)
        local t
        pcall(function() t = e:getTable() end)
        if t and tostring(t.Type) == "MSC_EngineComponentsWindow" then out[#out + 1] = t end
    end
    return out
end
local function mechUI() return getPlayerMechanicsUI and getPlayerMechanicsUI(pn) end
local function rect(e) return string.format("x=%d y=%d w=%d h=%d", math.floor(e:getX()), math.floor(e:getY()), math.floor(e:getWidth()), math.floor(e:getHeight())) end
local function both(tag)
    local ui = mechUI()
    if ui then say(string.format("%s: game mechanics window %s visible=%s", tag, rect(ui), tostring(ui:isReallyVisible()))) else say(tag .. ": no game mechanics window") end
    local ws = findMsc()
    if #ws == 0 then say(tag .. ": no Summer Car engine window") end
    for _, t in ipairs(ws) do say(string.format("%s: Summer Car engine window %s visible=%s title=%s activeTab=%s placement=%s", tag, rect(t), tostring(t:isReallyVisible()), tostring(t.title), tostring(t.activeTab),
        t.mechanicsPlacement and (string.format("tiledX=%s originalX=%s", tostring(t.mechanicsPlacement.tiledX), tostring(t.mechanicsPlacement.originalX))) or "nil")) end
end

local v, key
add("spawn", function()
    for _, o in ipairs({ { 4, 0 }, { -4, 0 }, { 0, 4 }, { 0, -4 }, { 5, 3 } }) do
        local sq = getCell():getGridSquare(math.floor(p:getX()) + o[1], math.floor(p:getY()) + o[2], 0)
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and not sq:HasTree() and not sq:getVehicleContainer() end) end
        if free and not v then v = addVehicleDebug("Base.CarNormal", IsoDirections.N, nil, sq) end
    end
    if not v then say("ERR no free square"); return true end
    pcall(function() key = p:getInventory():AddItem(v:createVehicleKey()) end)
    say("car at " .. math.floor(v:getX()) .. "," .. math.floor(v:getY()))
    return true
end)
wait(5000)
add("mod state", function()
    local C = MSC and MSC.EngineComponents
    pcall(function() say("initialized=" .. tostring(C.isInitialized(v)) .. " hoodOpen=" .. tostring(C.isHoodOpen(v)) .. " canAccessEngine=" .. tostring(C.canAccessEngine(v))) end)
    return true
end)
local t0, last, firstMsc, firstMech, hoodAt, seenMsc = nil, "", nil, nil, nil, 0
add("open mechanics", function() ISVehicleMenu.onMechanic(p, v); t0 = now(); say("onMechanic called"); return true end)
add("timeline", function()
    local ui = mechUI()
    local mv = ui and ui:isReallyVisible() or false
    local hood = v:getPartById("EngineDoor")
    local ho = hood and hood:getDoor() and hood:getDoor():isOpen() or false
    local ws = findMsc()
    local mc = #ws > 0
    local st = "mech=" .. tostring(mv) .. " hood=" .. tostring(ho) .. " msc=" .. tostring(mc)
    if st ~= last then say("t+" .. (now() - t0) .. " ms: " .. st); last = st end
    if mv and not firstMech then firstMech = now() - t0 end
    if ho and not hoodAt then hoodAt = now() - t0 end
    if mc then seenMsc = seenMsc + 1; if not firstMsc then firstMsc = now() - t0 end end
    if hoodAt and now() - t0 > hoodAt + 8000 then return true end
    if now() - t0 > 70000 then say("ERR the hood never opened (70 s)"); return true end
    return false
end)
add("after", function()
    say("first mechanics window visible at " .. tostring(firstMech) .. " ms, hood open at " .. tostring(hoodAt) .. " ms, Summer Car window first seen at " .. tostring(firstMsc) .. " ms")
    both("steady, hood open")
    shot("1_both_windows")
    return true
end)
wait(500)
add("contents", function()
    local ws = findMsc()
    local t = ws[1]
    if not t then say("no Summer Car window to describe"); return true end
    local keys = {}
    for k, val in pairs(t) do
        local tp = type(val)
        if tp == "table" and val.Type then keys[#keys + 1] = k .. "=" .. tostring(val.Type) end
    end
    table.sort(keys)
    say("Summer Car window children/panels: " .. table.concat(keys, ", "))
    local kids = {}
    pcall(function()
        local ch = t:getChildren()
        for _, c in pairs(ch) do local tt = c; pcall(function() tt = c:getTable() end); kids[#kids + 1] = tostring(tt and tt.Type or "?") end
    end)
    say("Summer Car window UI children: " .. table.concat(kids, ", "))
    return true
end)
-- the Engine part's right-click menu: the game's own function, through the bridge
add("engine menu", function()
    local ui = mechUI(); if not ui then return true end
    local part = v:getPartById("Engine")
    local ax, ay = ui:getWidth() / 2, 200
    local ok, e = pcall(function() ui.vehicle = v; ui.chr = p; ui:doPartContextMenu(part, ax, ay) end)
    say("doPartContextMenu(Engine) ok=" .. tostring(ok) .. (ok and "" or (" " .. tostring(e))))
    local names = {}
    if ui.context then for _, o in ipairs(ui.context.options or {}) do names[#names + 1] = tostring(o.name) .. (o.notAvailable and " [greyed]" or "") end end
    say("Engine part menu (" .. #names .. " options): " .. table.concat(names, ", "))
    return true
end)
wait(800)
add("shot menu", function() shot("2_engine_part_menu"); return true end)
add("close menu", function() local ui = mechUI(); pcall(function() if ui and ui.context then ui.context:closeAll() end end); return true end)
wait(500)
-- does the window close with the mechanics window
add("close mechanics", function() local ui = mechUI(); if ui then pcall(function() ui:close() end) end; say("mechanics window closed"); return true end)
wait(1500)
add("after close", function() both("after the mechanics window closed"); shot("3_after_mechanics_closed"); return true end)
-- reopen: does it come back at once (the hood is still open)
add("reopen", function() ISVehicleMenu.onMechanic(p, v); t0 = now(); last = ""; say("onMechanic again (hood already open)"); return true end)
add("timeline2", function()
    local ui = mechUI(); local mv = ui and ui:isReallyVisible() or false
    local mc = #findMsc() > 0
    local st = "mech=" .. tostring(mv) .. " msc=" .. tostring(mc)
    if st ~= last then say("again t+" .. (now() - t0) .. " ms: " .. st); last = st end
    return now() - t0 > 6000
end)
add("shot again", function() both("reopened"); shot("4_reopened"); return true end)
add("final close", function()
    local ui = mechUI(); if ui then pcall(function() ui:close() end) end
    for _, t in ipairs(findMsc()) do pcall(function() t:close(false) end) end
    pcall(function() ISTimedActionQueue.clear(p) end)
    pcall(function() if v then v:permanentlyRemove() end end)
    pcall(function() if key then p:getInventory():Remove(key) end end)
    say("put back: windows closed, car and key removed")
    return true
end)
wait(500)
add("done", function() say("DONE"); return true end)

local function tick()
    if qi == 0 then qi = 1; qstart = now() end
    local st = Q[qi]
    if not st then Events.OnTick.Remove(tick); return end
    local ok, r = pcall(st.fn)
    if not ok then say("ERR step '" .. st.n .. "': " .. tostring(r)); r = true end
    if not r and st.cap > 0 and now() - qstart > st.cap then say("ERR step '" .. st.n .. "' timed out"); r = true end
    if r then qi = qi + 1; qstart = now() end
end
Events.OnTick.Add(tick)
say("start (" .. #Q .. " steps)")
