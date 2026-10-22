-- ZeDUI/tools/qa/perf_bench_prof.lua  (Oct 22 2026)
-- Where the ZeD windows' frame time goes. After gallery_v3_core / clean / stage with ZeD on.
-- For each scene (pair on Loot, multi-column Loot, Maps tab), wraps every prerender / render
-- (and update) on the window trees with a getTimestampMs() timer, runs 12 s, and prints the
-- 12 costliest elements as ms per frame (inclusive of what that function draws itself; the
-- millisecond clock is unbiased over thousands of calls) next to the scene's total frame time.
-- Wrappers are taken off again. "ZEDQA pbp ..." ending "ZEDQA pbp DONE".
local TAG = "pbp"
local G = GAL
if not (G and G.spot and G.newSeq) then print("ZEDQA pbp ERR run gallery_v3_core/stage first"); print("ZEDQA pbp DONE"); return end
if not (ZeD and ZeD_CharacterWindow and ZeD_WorldWindow) then print("ZEDQA pbp ERR ZeD is not loaded"); print("ZEDQA pbp DONE"); return end
local S = G.newSeq(TAG, 900000)
local say = S.say
local p, core = G.p, G.core
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local P = { acc = {}, cnt = {}, wrapped = {}, frames = 0, t0 = 0, on = false, lock = nil }
local function onFrame()
    if P.on then P.frames = P.frames + 1 end
end
Events.OnRenderTick.Add(onFrame)

local function keyOf(o, how, depth)
    local nm = tostring(o.Type or "?")
    local w, h = 0, 0
    pcall(function() w, h = math.floor(o:getWidth()), math.floor(o:getHeight()) end)
    return string.format("%s %s %dx%d d%d", nm, how, w, h, depth)
end
local function wrap(o, how, depth)
    local orig = o[how]
    if type(orig) ~= "function" then return end
    local key = keyOf(o, how, depth)
    local mine = rawget(o, how)
    P.wrapped[#P.wrapped + 1] = { o = o, how = how, mine = mine }
    o[how] = function(...)
        local t = getTimestampMs()
        local a, b, c = orig(...)
        P.acc[key] = (P.acc[key] or 0) + (getTimestampMs() - t)
        P.cnt[key] = (P.cnt[key] or 0) + 1
        return a, b, c
    end
end
local function walk(o, depth, seen)
    if not o or seen[o] or depth > 8 then return end
    seen[o] = true
    wrap(o, "prerender", depth)
    wrap(o, "render", depth)
    wrap(o, "update", depth)
    if type(o.children) == "table" then
        for _, ch in pairs(o.children) do if type(ch) == "table" then walk(ch, depth + 1, seen) end end
    end
end
local function unwrapAll()
    for _, w in ipairs(P.wrapped) do w.o[w.how] = w.mine end
    P.wrapped = {}
end
local function report(scene, frameMs)
    local rows, total = {}, 0
    for k, v in pairs(P.acc) do
        rows[#rows + 1] = { k = k, ms = v / math.max(P.frames, 1), n = P.cnt[k] / math.max(P.frames, 1) }
        if k:find("render", 1, true) then total = total + v / math.max(P.frames, 1) end
    end
    table.sort(rows, function(a, b) return a.ms > b.ms end)
    say(string.format("PROF|%s|frames=%d|frameMs=%.2f|sumPreRender=%.2f", scene, P.frames, frameMs, total))
    for i = 1, math.min(12, #rows) do
        say(string.format("PROF|%s|%.3f ms/frame|%.2f calls/frame|%s", scene, rows[i].ms, rows[i].n, rows[i].k))
    end
end

function P.CW() return CWm.getWindow() end
function P.WW() return WWm.getWindow() end
function P.place()
    local c, w = P.CW(), P.WW()
    if not (c and w and CWm.isOpen() and WWm.isOpen() and not w._rolled) then return end
    local L = P.lock
    if not L then
        local gap = ZeD.T and ZeD.T.px and ZeD.T.px(8) or 16
        local x0 = math.floor((core:getScreenWidth() - (c:getWidth() + gap + w:getWidth())) / 2)
        L = { right = x0 + c:getWidth(), left = x0 + c:getWidth() + gap, cy = c:getY(), wy = w:getY() }
        P.lock = L
    end
    c._anchorRightEdge = L.right
    c:setX(L.right - c:getWidth()); w:setX(L.left); c:setY(L.cy); w:setY(L.wy)
end
local function goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
local function colOn(win, inv)
    for i, c in ipairs(win._containers or {}) do
        if c.inventory == inv then
            for _, j in ipairs(win._mcSelected or {}) do if j == i then return true end end
            return false
        end
    end
    return false
end
local function mc(on)
    local c, w = P.CW(), P.WW()
    local lists = { { c, CWm, {} }, { w, WWm, {} } }
    for _, k in ipairs({ "back" }) do if G.bags and G.bags[k] then lists[1][3][#lists[1][3] + 1] = G.bags[k]:getInventory() end end
    if G.trunk then lists[2][3][#lists[2][3] + 1] = G.trunk end
    if G.duffel then lists[2][3][#lists[2][3] + 1] = G.duffel:getInventory() end
    for _, l in ipairs(lists) do
        for _, inv in ipairs(l[3]) do
            if colOn(l[1], inv) ~= on then l[2].toggleColumn(inv) end
        end
    end
end

local function scene(name, setup, ready)
    S.step(3, function()
        G.faceFront(); G.day()
        if getGameSpeed() <= 0 then setGameSpeed(1) end
        if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
        P.place()
        pcall(setup)
    end)
    local tries = 0
    S.poll(5, 6000, function()
        tries = tries + 1
        P.place()
        if tries > 300 then return true end
        return ready == nil or ready() == true
    end)
    S.step(200, function()
        local seen = {}
        walk(P.CW(), 0, seen); walk(P.WW(), 0, seen)
        P.acc, P.cnt, P.frames, P.on = {}, {}, 0, true
        P.t0 = getTimestampMs()
    end)
    S.poll(0, 4000000, function() return getTimestampMs() - P.t0 >= 12000 end)
    S.step(0, function()
        P.on = false
        local ft = (getTimestampMs() - P.t0) / math.max(P.frames, 1)
        unwrapAll()
        report(name, ft)
    end)
    S.step(5, function() end)
end

S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.cleanLook(); G.day(); G.stand()
    pcall(function() p:getStats():set(CharacterStat.HUNGER, 0); p:getStats():set(CharacterStat.THIRST, 0) end)
end)
S.zoomTo(1.0)
scene("pair_loot", function() goTab(P.CW(), P.CW()._tabStripPanel, "loot"); goTab(P.WW(), P.WW()._actionTabStrip, "loot"); mc(false) end,
    function() mc(false); return true end)
scene("pair_multicolumn", function() goTab(P.CW(), P.CW()._tabStripPanel, "loot"); goTab(P.WW(), P.WW()._actionTabStrip, "loot") end,
    function() mc(true); return true end)
scene("world_maps", function() mc(false); goTab(P.CW(), P.CW()._tabStripPanel, "loot"); goTab(P.WW(), P.WW()._actionTabStrip, "maps") end)
scene("world_craft", function() goTab(P.WW(), P.WW()._actionTabStrip, "craft") end)
S.step(2, function()
    goTab(P.WW(), P.WW()._actionTabStrip, "loot")
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(0) end
end)
S.step(10, function() Events.OnRenderTick.Remove(onFrame); unwrapAll() end)
S.start()
