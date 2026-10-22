-- ZeDUI/tools/qa/perf_bench_uie.lua  (Oct 22 2026)
-- Every top-level UI element the game holds (Java UIManager list), with its Lua children,
-- timed on update / prerender / render for 12 s in two states: windows shut (HUD) and every
-- UI element hidden. Prints the 16 costliest as ms per frame. Works with ZeD on or off (the
-- keys carry the element's Lua type name and size). After gallery_v3_core / clean / stage.
-- "ZEDQA pbu ..." ending "ZEDQA pbu DONE".
local G = GAL
if not (G and G.spot and G.newSeq) then print("ZEDQA pbu ERR run gallery_v3_core/stage first"); print("ZEDQA pbu DONE"); return end
local S = G.newSeq("pbu", 600000)
local say = S.say
local U = { acc = {}, cnt = {}, wrapped = {}, frames = 0, on = false, t0 = 0, nTop = 0, nAll = 0 }
local function onFrame() if U.on then U.frames = U.frames + 1 end end
Events.OnRenderTick.Add(onFrame)
local function keyOf(o, how, depth)
    local w, h, vis = 0, 0, "?"
    pcall(function() w, h = math.floor(o:getWidth()), math.floor(o:getHeight()) end)
    pcall(function() vis = tostring(o:isVisible()) end)
    local lbl = tostring(o._zedLabel or o.title or o.name or "")
    if #lbl > 24 then lbl = lbl:sub(1, 24) end
    return string.format("%s %s %dx%d d%d vis=%s %s", tostring(o.Type or "?"), how, w, h, depth, vis, lbl)
end
local function wrap(o, how, depth)
    local orig = o[how]
    if type(orig) ~= "function" then return end
    local key = keyOf(o, how, depth)
    U.wrapped[#U.wrapped + 1] = { o = o, how = how, mine = rawget(o, how) }
    o[how] = function(...)
        local t = getTimestampMs()
        local a, b, c = orig(...)
        U.acc[key] = (U.acc[key] or 0) + (getTimestampMs() - t)
        U.cnt[key] = (U.cnt[key] or 0) + 1
        return a, b, c
    end
end
local function walk(o, depth, seen)
    if type(o) ~= "table" or seen[o] or depth > 6 then return end
    seen[o] = true
    U.nAll = U.nAll + 1
    wrap(o, "update", depth); wrap(o, "prerender", depth); wrap(o, "render", depth)
    if type(o.children) == "table" then for _, ch in pairs(o.children) do walk(ch, depth + 1, seen) end end
end
local function unwrapAll()
    for _, w in ipairs(U.wrapped) do w.o[w.how] = w.mine end
    U.wrapped = {}
end
local function wrapAllTop()
    local seen = {}
    U.nTop, U.nAll = 0, 0
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local t = nil
        pcall(function() t = ui:get(i):getTable() end)
        if t then U.nTop = U.nTop + 1; walk(t, 0, seen) end
    end
end
local function report(scene, frameMs)
    local rows, tot = {}, 0
    for k, v in pairs(U.acc) do
        local ms = v / math.max(U.frames, 1)
        rows[#rows + 1] = { k = k, ms = ms, n = U.cnt[k] / math.max(U.frames, 1) }
        tot = tot + ms
    end
    table.sort(rows, function(a, b) return a.ms > b.ms end)
    say(string.format("UIE|%s|frames=%d|frameMs=%.2f|top-level=%d elements=%d|sum=%.2f ms/frame", scene, U.frames, frameMs, U.nTop, U.nAll, tot))
    for i = 1, math.min(16, #rows) do
        say(string.format("UIE|%s|%.3f ms/frame|%.2f calls/frame|%s", scene, rows[i].ms, rows[i].n, rows[i].k))
    end
end
local function scene(name, setup, off)
    S.step(3, function() G.faceFront(); G.day(); if getGameSpeed() <= 0 then setGameSpeed(1) end; pcall(setup) end)
    S.step(200, function()
        wrapAllTop()
        U.acc, U.cnt, U.frames, U.on, U.t0 = {}, {}, 0, true, getTimestampMs()
    end)
    S.poll(0, 4000000, function() return getTimestampMs() - U.t0 >= 12000 end)
    S.step(0, function()
        U.on = false
        local ft = (getTimestampMs() - U.t0) / math.max(U.frames, 1)
        unwrapAll()
        report(name, ft)
        if off then pcall(off) end
    end)
end
S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.cleanLook(); G.day(); G.stand()
    if ZeD_CharacterWindow and ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
    pcall(function() getPlayerInventory(G.pn):setVisible(false); getPlayerLoot(G.pn):setVisible(false) end)
end)
S.zoomTo(1.0)
scene("hud", function() end)
scene("bare", function() UIManager.setVisibleAllUI(false) end, function() UIManager.setVisibleAllUI(true) end)
S.step(10, function() Events.OnRenderTick.Remove(onFrame); unwrapAll() end)
S.start()
