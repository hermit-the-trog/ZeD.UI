-- ZeDUI/tools/qa/perf_bench_zed.lua  (Oct 22 2026)
-- Frame-time benchmark, the ZeD-UI half. After gallery_v3_core.lua, gallery_v3_reveal.lua
-- and gallery_v3_stage.lua (the Valley Station lot: geared character, trunk, duffel, cars,
-- passive zombies), with ZeD on. Pair: perf_bench_van.lua (ZeD off, the same scenes).
-- Seven scenarios, each: set up, 5 s settle, 30 s recorded with getTimestampMs() deltas in
-- Events.OnRenderTick:
--   hud     windows shut: belt, moodles on        inv    both windows, multi-column Loot
--   card    item card open on an apple            map    Maps tab open
--   car     in the station wagon at night, engine on, lights on, the dash
--   idle    nothing open, no moodles (baseline)   bare   all UI hidden (render floor, extra)
-- Passes: capped (the game's own settings) x2, then uncapped (vsync off, no frame limit,
-- UI render limit raised; in memory only, put back at the end) x2.
-- Prints "ZEDQA pbz RES|<mode>|<rep>|<scene>|frames|avg|median|p95|p99|worst|fps|engineFPS|
-- cpu|gpu|cpuWait|gpuWait|over16|over33|note". Ends "ZEDQA pbz DONE".
local TAG = "pbz"
local G = GAL
if not (G and G.spot and G.car and G.newSeq) then print("ZEDQA " .. TAG .. " ERR run gallery_v3_core/stage first"); print("ZEDQA " .. TAG .. " DONE"); return end
if not (ZeD and ZeD_CharacterWindow and ZeD_WorldWindow) then print("ZEDQA " .. TAG .. " ERR ZeD is not loaded"); print("ZEDQA " .. TAG .. " DONE"); return end
local S = G.newSeq(TAG, 4200000)
local say = S.say
local p, pn, core = G.p, G.pn, G.core
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local perf = getPerformance()
local SETTLE_MS, REC_MS = 5000, 30000
local Z = { lock = nil, was = {}, car = { f = 0 } }
Z.was.mapStyle = nil
PERF_WAS = PERF_WAS or nil

-- ---------------------------------------------------------------------------
-- the recorder
-- ---------------------------------------------------------------------------
local B = { on = false, n = 0, last = 0, ds = {}, t0 = 0, sum = 0, cpu = 0, gpu = 0, cpuw = 0, gpuw = 0, timers = false, fail = false }
pcall(function() local a, b = getCPUTime(), getGPUTime(); B.timers = (a ~= nil and b ~= nil) end)
local function onFrame()
    if not B.on then return end
    local now = getTimestampMs()
    if B.last > 0 then
        local d = now - B.last
        B.n = B.n + 1
        B.ds[B.n] = d
        B.sum = B.sum + d
        if B.timers then
            B.cpu = B.cpu + getCPUTime(); B.gpu = B.gpu + getGPUTime()
            B.cpuw = B.cpuw + getCPUWait(); B.gpuw = B.gpuw + getGPUWait()
        end
    end
    B.last = now
end
Events.OnRenderTick.Add(onFrame)
function B.reset()
    B.n, B.sum, B.cpu, B.gpu, B.cpuw, B.gpuw, B.last, B.ds = 0, 0, 0, 0, 0, 0, 0, {}
end
local function pct(a, q)
    local i = math.floor(#a * q + 0.5)
    if i < 1 then i = 1 end
    if i > #a then i = #a end
    return a[i]
end
function B.report(mode, rep, id, note)
    local n = B.n
    if n < 2 then say("ERR no frames recorded for " .. id); return end
    local a = B.ds
    local o16, o33 = 0, 0
    for i = 1, n do
        if a[i] > 16.7 then o16 = o16 + 1 end
        if a[i] > 33.4 then o33 = o33 + 1 end
    end
    table.sort(a)
    local avg = B.sum / n
    local eng = 0
    pcall(function() eng = getAverageFPS() end)
    say(string.format("RES|%s|%d|%s|%d|%.3f|%.1f|%.1f|%.1f|%d|%.1f|%s|%.2f|%.2f|%.2f|%.2f|%d|%d|%s",
        mode, rep, id, n, avg, pct(a, 0.5), pct(a, 0.95), pct(a, 0.99), a[n], 1000 / avg, tostring(eng),
        B.cpu / n, B.gpu / n, B.cpuw / n, B.gpuw / n, o16, o33, note or ""))
end

-- ---------------------------------------------------------------------------
-- engine limits (in memory only)
-- ---------------------------------------------------------------------------
local function lim()
    local t = {}
    pcall(function() t.vsync = core:getOptionVSync() end)
    pcall(function() t.unc = perf:isFramerateUncapped() end)
    pcall(function() t.lock = perf:getFramerate() end)
    pcall(function() t.ui = core:getOptionUIRenderFPS() end)
    return t
end
local function limStr(t) return "vsync=" .. tostring(t.vsync) .. " uncapped=" .. tostring(t.unc) .. " lock=" .. tostring(t.lock) .. " uiRender=" .. tostring(t.ui) end
local function setMode(mode)
    if not PERF_WAS then PERF_WAS = lim() end
    local w = PERF_WAS
    if mode == "capped" then
        pcall(function() core:setOptionVSync(w.vsync) end)
        pcall(function() perf:setFramerateUncapped(w.unc) end)
        pcall(function() core:setOptionUIRenderFPS(w.ui) end)
    else
        pcall(function() core:setOptionVSync(false) end)
        pcall(function() perf:setFramerateUncapped(true) end)
        pcall(function() core:setOptionUIRenderFPS(240) end)
    end
    say("mode " .. mode .. ": " .. limStr(lim()) .. " (was " .. limStr(w) .. ")")
end

-- ---------------------------------------------------------------------------
-- ZeD helpers (as gallery_v3_zed.lua)
-- ---------------------------------------------------------------------------
function Z.CW() return CWm.getWindow() end
function Z.WW() return WWm.getWindow() end
function Z.closePair()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(0)
    else
        if CWm.isOpen() then CWm.toggle(0) end
        if WWm.isOpen() then WWm.close() end
    end
end
function Z.place()
    local c, w = Z.CW(), Z.WW()
    if not (c and w and CWm.isOpen() and WWm.isOpen()) then return false end
    if w._rolled then return false end
    local L = Z.lock
    if not L then
        local gap = ZeD.T and ZeD.T.px and ZeD.T.px(8) or 16
        local x0 = math.floor((core:getScreenWidth() - (c:getWidth() + gap + w:getWidth())) / 2)
        L = { right = x0 + c:getWidth(), left = x0 + c:getWidth() + gap, cy = c:getY(), wy = w:getY() }
        Z.lock = L
    end
    c._anchorRightEdge = L.right
    c:setX(L.right - c:getWidth())
    w:setX(L.left)
    c:setY(L.cy)
    w:setY(L.wy)
    return true
end
function Z.openPair()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
    Z.place()
end
function Z.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
function Z.charTab(id) local w = Z.CW(); return (w and Z.goTab(w, w._tabStripPanel, id)) and true or false end
function Z.worldTab(id) local w = Z.WW(); return (w and Z.goTab(w, w._actionTabStrip, id)) and true or false end
function Z.colOn(win, inv)
    if not (win and inv) then return false end
    for i, c in ipairs(win._containers or {}) do
        if c.inventory == inv then
            for _, j in ipairs(win._mcSelected or {}) do if j == i then return true end end
            return false
        end
    end
    return false
end
function Z.mcList()
    local cl, wl = {}, {}
    for _, k in ipairs({ "back", "webbing" }) do
        local b = G.bags and G.bags[k]
        if b then cl[#cl + 1] = b:getInventory() end
    end
    if G.trunk then wl[#wl + 1] = G.trunk end
    if G.duffel then wl[#wl + 1] = G.duffel:getInventory() end
    return cl, wl
end
function Z.mc(on)
    local c, w = Z.CW(), Z.WW()
    if not (c and w) then return false end
    if on then Z.charTab("loot"); Z.worldTab("loot") end
    local cl, wl = Z.mcList()
    local done = true
    for _, inv in ipairs(cl) do
        if Z.colOn(c, inv) ~= on then CWm.toggleColumn(inv); done = false end
    end
    for _, inv in ipairs(wl) do
        if Z.colOn(w, inv) ~= on then WWm.toggleColumn(inv); done = false end
    end
    return done
end
function Z.sort(win, key, asc)
    local c = win and win._mainContent
    if not c then return end
    c._sortCol, c._sortAsc = key, asc
    for _, cs in ipairs(c._colStates or {}) do cs.sortCol, cs.sortAsc = key, asc end
end
function Z.selectItem(item)
    local w = Z.CW()
    local c = w and w._mainContent
    if not c then return false end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    c._selectedItems, c._lastClickedItem = sel, item
    w._updateDrawer(c)
    return true
end
function Z.found(ft)
    local items = G.inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it:getFullType() == ft then return it end
    end
    return nil
end
function Z.mp() local w = Z.WW(); return w and w._worldMapPanel end

-- ---------------------------------------------------------------------------
-- scenes
-- ---------------------------------------------------------------------------
local function moodles(on)
    pcall(function()
        local st = p:getStats()
        st:set(CharacterStat.HUNGER, on and 0.3 or 0)
        st:set(CharacterStat.THIRST, on and 0.35 or 0)
    end)
end
local function carNote()
    local v = p:getVehicle()
    if not v then return "" end
    local eng, hl = false, false
    pcall(function() eng = v:isEngineRunning() end)
    pcall(function() hl = v:getHeadlightsOn() end)
    local dash = false
    pcall(function() dash = (ZeD.Dashboard and ZeD.Dashboard.getInstance() ~= nil) end)
    return "engine=" .. tostring(eng) .. " lights=" .. tostring(hl) .. " dash=" .. tostring(dash)
end
local SC = {}
SC[#SC + 1] = { id = "hud", moodles = true,
    setup = function() Z.closePair() end,
    note = function() return "windows " .. tostring(CWm.isOpen()) .. "/" .. tostring(WWm.isOpen()) end }
SC[#SC + 1] = { id = "inv", moodles = true,
    setup = function() Z.mcTries = 0; Z.openPair(); Z.charTab("loot"); Z.worldTab("loot") end,
    poll = function()
        Z.place()
        Z.mcTries = (Z.mcTries or 0) + 1
        local done = Z.mc(true)
        if done or Z.mcTries > 400 then Z.sort(Z.CW(), "cat", true); Z.sort(Z.WW(), "name", true); return true end
        return false
    end,
    note = function()
        local c, w = Z.CW(), Z.WW()
        return "columns char " .. tostring(c and #(c._mcSelected or {})) .. " world " .. tostring(w and #(w._mcSelected or {}))
    end }
SC[#SC + 1] = { id = "card", moodles = true,
    setup = function() Z.openPair(); Z.charTab("loot"); Z.worldTab("loot") end,
    poll = function()
        Z.place()
        if not Z.mc(false) then return false end
        local it = Z.found("Base.Apple")
        if not it then return true end
        return Z.selectItem(it)
    end,
    off = function() Z.selectItem(nil) end,
    note = function() local w = Z.CW(); local c = w and w._mainContent; local n = 0; for _ in pairs(c and c._selectedItems or {}) do n = n + 1 end; return "selected " .. n end }
SC[#SC + 1] = { id = "map", moodles = true,
    setup = function() Z.openPair(); Z.charTab("loot"); Z.worldTab("maps"); Z.mapTries = 0 end,
    poll = function()
        Z.place()
        Z.mapTries = Z.mapTries + 1
        local m, w = Z.mp(), Z.WW()
        if not (m and w) then return Z.mapTries > 200 end
        Z.was.mapStyle = Z.was.mapStyle or m.style
        ZeD.MapsTab.setStyle(w, "survey")
        pcall(function() Z.mp().mapAPI:centerOn(p:getX(), p:getY()) end)
        pcall(function() Z.mp():_zoomTo(15) end)
        return true
    end,
    off = function()
        local w = Z.WW()
        if w and Z.was.mapStyle then pcall(ZeD.MapsTab.setStyle, w, Z.was.mapStyle) end
        Z.worldTab("loot")
    end,
    note = function() return "map panel " .. tostring(Z.mp() ~= nil) end }
SC[#SC + 1] = { id = "car", moodles = true, night = true,
    setup = function()
        Z.closePair()
        local C = Z.car
        C.f, C.tries, C.last, C.lit, C.litAt = 0, 0, -9999, false, 0
        local v = G.car
        local d = 99
        pcall(function() d = v:DistTo(p) end)
        if d > 12 then error("car " .. d .. " away") end
        pcall(function() v:enter(0, p) end)
        C.entered = p:getVehicle() ~= nil
        if C.entered then pcall(function() triggerEvent("OnEnterVehicle", p) end) end
        if not C.entered then error("could not get in") end
    end,
    poll = function()
        local C, v = Z.car, G.car
        C.f = C.f + 1
        if C.f == 30 then pcall(function() v:setKeysInIgnition(true) end) end
        local run = false
        pcall(function() run = v:isEngineRunning() end)
        if not run then
            local q = ISTimedActionQueue.getTimedActionQueue(p)
            local busy = q and q.queue and #q.queue > 0
            if not busy and C.f - C.last > 120 and C.tries < 5 then
                C.tries = C.tries + 1; C.last = C.f
                pcall(function() ISVehicleMenu.onStartEngine(p) end)
            end
            return false
        end
        if not C.litAt or C.litAt == 0 then C.litAt = C.f end
        if C.f - C.litAt < 60 then return false end
        if not C.lit then
            C.lit = true
            local on = false
            pcall(function() on = v:getHeadlightsOn() end)
            if not on then
                local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
                if d and d._st and not d._st.lights then pcall(function() d:_fire("lights", false) end) end
                pcall(function() on = v:getHeadlightsOn() end)
                if not on then pcall(function() ISVehicleMenu.onToggleHeadlights(p) end) end
            end
            return false
        end
        return C.f - C.litAt >= 120
    end,
    off = function()
        G.dayAgain()
        local v = p:getVehicle()
        if v then pcall(function() v:exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
    end,
    after = function() G.stand(); G.openTrunk(G.car); G.faceFront() end,
    note = carNote }
SC[#SC + 1] = { id = "idle", moodles = false,
    setup = function() Z.closePair() end,
    note = function() return "windows " .. tostring(CWm.isOpen()) .. "/" .. tostring(WWm.isOpen()) end }
SC[#SC + 1] = { id = "bare", moodles = false,
    setup = function() Z.closePair(); UIManager.setVisibleAllUI(false) end,
    off = function() UIManager.setVisibleAllUI(true) end,
    note = function() return "all UI hidden" end }

-- ---------------------------------------------------------------------------
-- the sequence
-- ---------------------------------------------------------------------------
local function waitMs(ms)
    local t0 = nil
    S.poll(0, 4000000, function()
        t0 = t0 or getTimestampMs()
        return getTimestampMs() - t0 >= ms
    end)
end
local function addScenario(mode, rep, sc)
    S.step(3, function()
        B.fail = false
        G.faceFront()
        if sc.night then G.night() else G.day() end
        moodles(sc.moodles)
        local ok, e = pcall(sc.setup)
        if not ok then B.fail = true; S.err(mode .. " " .. sc.id, e) end
    end)
    if sc.poll then
        S.poll(5, 30000, function()
            if B.fail then return true end
            local ok, r = pcall(sc.poll)
            if not ok then B.fail = true; S.err(sc.id .. " poll", r); return true end
            return r == true
        end, function() B.fail = true; say("note: " .. sc.id .. " did not get ready") end)
    end
    waitMs(SETTLE_MS)
    S.step(0, function() B.reset(); B.on = true; B.t0 = getTimestampMs() end)
    S.poll(0, 4000000, function() return getTimestampMs() - B.t0 >= REC_MS end)
    S.step(0, function()
        B.on = false
        local note = ""
        pcall(function() note = sc.note and sc.note() or "" end)
        if B.fail then note = "SETUP FAILED " .. note end
        B.report(mode, rep, sc.id, note)
    end)
    S.step(2, function()
        if sc.off then pcall(sc.off) end
    end)
    if sc.after then
        S.step(40, function() pcall(sc.after) end)
    end
end

S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.cleanLook()
    G.day()
    pcall(ZeD.Settings.reapplyFromOptions)
    G.stand()
    say(string.format("start: ZeD scale %s theme %s %s | screen %dx%d | zoom %s | timers %s", tostring(ZeD.Scale and ZeD.Scale.current and ZeD.Scale.current()),
        tostring(ZeD.currentBase), tostring(ZeD.currentAccent), core:getScreenWidth(), core:getScreenHeight(), tostring(core:getZoom(0)), tostring(B.timers)))
    PERF_WAS = lim()
    say("limits at start: " .. limStr(PERF_WAS))
end)
S.zoomTo(1.0)
for _, mode in ipairs({ "capped", "uncapped" }) do
    S.step(2, function() setMode(mode) end)
    S.step(60, function() end)
    for rep = 1, 2 do
        for _, sc in ipairs(SC) do addScenario(mode, rep, sc) end
    end
end
S.step(2, function()
    setMode("capped")
    pcall(function() UIManager.setVisibleAllUI(true) end)
    Z.closePair()
    G.dayAgain()
    Events.OnRenderTick.Remove(onFrame)
    say("limits at end: " .. limStr(lim()))
end)
S.start()
