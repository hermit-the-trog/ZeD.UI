-- ZeDUI/tools/qa/perf_bench_van.lua  (Oct 22 2026)
-- Frame-time benchmark, the vanilla half (ZeD-UI OFF, ZeDQAShim loaded). After gallery_v3_core.lua, gallery_v3_reveal.lua
-- and gallery_v3_stage.lua (the Valley Station lot: geared character, trunk, duffel, cars,
-- passive zombies), with ZeD off. Pair: perf_bench_zed.lua (the same scenes).
-- Seven scenarios, each: set up, 5 s settle, 30 s recorded with getTimestampMs() deltas in
-- Events.OnRenderTick:
--   hud     windows shut: belt, moodles on        inv    both windows, multi-column Loot
--   card    item card open on an apple            map    Maps tab open
--   car     in the station wagon at night, engine on, lights on, the dash
--   idle    nothing open, no moodles (baseline)   bare   all UI hidden (render floor, extra)
-- Passes: capped (the game's own settings) x2, then uncapped (vsync off, no frame limit,
-- UI render limit raised; in memory only, put back at the end) x2.
-- Prints "ZEDQA pbv RES|<mode>|<rep>|<scene>|frames|avg|median|p95|p99|worst|fps|engineFPS|
-- cpu|gpu|cpuWait|gpuWait|over16|over33|note". Ends "ZEDQA pbv DONE".
local TAG = "pbv"
local G = GAL
if not (G and G.spot and G.car and G.newSeq) then print("ZEDQA " .. TAG .. " ERR run gallery_v3_core/stage first"); print("ZEDQA " .. TAG .. " DONE"); return end
if ZeD and ZeD_CharacterWindow then print("ZEDQA " .. TAG .. " ERR ZeD-UI is loaded: this run is for ZeD off"); print("ZEDQA " .. TAG .. " DONE"); return end
local S = G.newSeq(TAG, 4200000)
local say = S.say
local p, pn, core = G.p, G.pn, G.core
local perf = getPerformance()
local SETTLE_MS, REC_MS = 5000, 30000
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
-- vanilla helpers (as gallery_v3_van.lua)
-- ---------------------------------------------------------------------------
local V = { car = { f = 0 } }
function V.found(ft)
    local items = G.inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it:getFullType() == ft then return it end
    end
    return nil
end
function V.pages(on, c)
    local pi, pl = getPlayerInventory(pn), getPlayerLoot(pn)
    if not (pi and pl) then return false end
    if not on then
        pi:setVisible(false); pl:setVisible(false)
        return true
    end
    local d = getPlayerData(pn)
    pcall(function()
        d:placeInventoryScreens(pn, 1, true)
        pi:setX(d.x1); pi:setY(d.y1); pi:setWidth(d.w1); pi:setHeight(d.h1)
        pl:setX(d.x2); pl:setY(d.y2); pl:setWidth(d.w2); pl:setHeight(d.h2)
    end)
    for _, pg in ipairs({ pi, pl }) do
        pg:setVisible(true)
        pcall(function() pg:setPinned() end)
        pcall(function() pg.isCollapsed = false; pg:setMaxDrawHeight(-1) end)
    end
    if c then pcall(function() pl:setForceSelectedContainer(c, 60000) end) end
    return true
end
function V.tip(it)
    if V.tipW then pcall(function() V.tipW:removeFromUIManager() end); V.tipW = nil end
    if not it then return true end
    local pi = getPlayerInventory(pn)
    local t = ISToolTipInv:new(it)
    t:initialise()
    t:addToUIManager()
    t:setVisible(true)
    t:setOwner(pi and pi.inventoryPane)
    t:setCharacter(p)
    t.followMouse = false
    local x = pi and (pi:getX() + pi:getWidth() + 10) or 400
    local y = pi and (pi:getY() + 60) or 200
    pcall(function() t:setDesiredPosition(x, y) end)
    t:setX(x); t:setY(y)
    V.tipW = t
    return true
end

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
    return "engine=" .. tostring(eng) .. " lights=" .. tostring(hl)
end
local function pagesNote()
    local pi, pl = getPlayerInventory(pn), getPlayerLoot(pn)
    return "inventory " .. tostring(pi and pi:isVisible()) .. " loot " .. tostring(pl and pl:isVisible())
end
local SC = {}
SC[#SC + 1] = { id = "hud", moodles = true,
    setup = function() V.pages(false) end,
    note = pagesNote }
SC[#SC + 1] = { id = "inv", moodles = true,
    setup = function() V.pages(true, G.trunk) end,
    note = pagesNote }
SC[#SC + 1] = { id = "card", moodles = true,
    setup = function()
        V.pages(true, G.trunk)
        local it = V.found("Base.Apple")
        if not it then error("no apple") end
        V.tip(it)
    end,
    off = function() V.tip(nil) end,
    note = function() return pagesNote() .. " tooltip " .. tostring(V.tipW ~= nil) end }
SC[#SC + 1] = { id = "map", moodles = true,
    setup = function()
        V.tip(nil); V.pages(false)
        ISWorldMap.ShowWorldMap(pn, p:getX(), p:getY(), 15)
    end,
    off = function() pcall(function() ISWorldMap.HideWorldMap(pn) end) end,
    note = function() return "speed " .. tostring(getGameSpeed()) end }
SC[#SC + 1] = { id = "car", moodles = true, night = true,
    setup = function()
        V.pages(false)
        local C = V.car
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
        local C, v = V.car, G.car
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
            if not on then pcall(function() ISVehicleMenu.onToggleHeadlights(p) end) end
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
    setup = function() V.pages(false) end,
    note = pagesNote }
SC[#SC + 1] = { id = "bare", moodles = false,
    setup = function() V.pages(false); UIManager.setVisibleAllUI(false) end,
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
    G.stand()
    say(string.format("start: vanilla | font size %s inv font %s tooltip font %s moodles %s sidebar %s | screen %dx%d | zoom %s | timers %s", tostring(core:getOptionFontSize()), tostring(core:getOptionInventoryFont()), tostring(core:getOptionTooltipFont()), tostring(core:getOptionMoodleSize()), tostring(core:getOptionSidebarSize()),
        core:getScreenWidth(), core:getScreenHeight(), tostring(core:getZoom(0)), tostring(B.timers)))
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
    V.pages(false)
    G.dayAgain()
    Events.OnRenderTick.Remove(onFrame)
    say("limits at end: " .. limStr(lim()))
end)
S.start()
