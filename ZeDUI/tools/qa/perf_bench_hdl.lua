-- ZeDUI/tools/qa/perf_bench_hdl.lua  (Oct 22 2026)
-- Which Events handlers cost frame time, with ZeD on. Needs the dev-only mod ZeDPerfProbe listed
-- before ZeD_UI in the QA save's mods.txt (it times every Events.X.Add handler). After
-- gallery_v3_core / clean / stage. Scenes: windows shut (HUD), all UI hidden, pair open on Loot.
-- Prints the 14 costliest handlers as ms per frame. "ZEDQA pbh ..." ending "ZEDQA pbh DONE".
local G = GAL
if not (G and G.spot and G.newSeq) then print("ZEDQA pbh ERR run gallery_v3_core/stage first"); print("ZEDQA pbh DONE"); return end
if not (ZeD and ZeD_CharacterWindow and ZPROBE) then print("ZEDQA pbh ERR ZeD or the probe is not loaded"); print("ZEDQA pbh DONE"); return end
local S = G.newSeq("pbh", 600000)
local say = S.say
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local H = { frames = 0, on = false, t0 = 0 }
local function onFrame() if H.on then H.frames = H.frames + 1 end end
Events.OnRenderTick.Add(onFrame)
say("handlers wrapped: " .. ZPROBE.n .. " on " .. ZPROBE.wrapped .. " events | sample desc: " .. tostring(ZPROBE.h[1] and ZPROBE.h[1].desc))
local function report(scene, frameMs)
    local rows, byEv, tot = {}, {}, 0
    for i = 1, ZPROBE.n do
        local r = ZPROBE.h[i]
        if r.calls > 0 then
            rows[#rows + 1] = { i = i, r = r, ms = r.ms / math.max(H.frames, 1) }
            byEv[r.ev] = (byEv[r.ev] or 0) + r.ms / math.max(H.frames, 1)
            tot = tot + r.ms / math.max(H.frames, 1)
        end
    end
    table.sort(rows, function(a, b) return a.ms > b.ms end)
    say(string.format("HDL|%s|frames=%d|frameMs=%.2f|allHandlers=%.2f ms/frame", scene, H.frames, frameMs, tot))
    local evs = {}
    for k, v in pairs(byEv) do evs[#evs + 1] = { k = k, v = v } end
    table.sort(evs, function(a, b) return a.v > b.v end)
    for i = 1, math.min(6, #evs) do say(string.format("HDL|%s|event %s|%.3f ms/frame", scene, evs[i].k, evs[i].v)) end
    for i = 1, math.min(14, #rows) do
        local x = rows[i]
        say(string.format("HDL|%s|#%d %s|%.3f ms/frame|%.2f calls/frame|%s", scene, x.i, x.r.ev, x.ms, x.r.calls / math.max(H.frames, 1), x.r.desc))
    end
end
local function scene(name, setup, off)
    S.step(3, function() G.faceFront(); G.day(); if getGameSpeed() <= 0 then setGameSpeed(1) end; pcall(setup) end)
    S.step(240, function()
        for i = 1, ZPROBE.n do ZPROBE.h[i].ms = 0; ZPROBE.h[i].calls = 0 end
        H.frames, H.on, ZPROBE.on, H.t0 = 0, true, true, getTimestampMs()
    end)
    S.poll(0, 4000000, function() return getTimestampMs() - H.t0 >= 12000 end)
    S.step(0, function()
        H.on, ZPROBE.on = false, false
        report(name, (getTimestampMs() - H.t0) / math.max(H.frames, 1))
        if off then pcall(off) end
    end)
end
S.step(2, function() if getGameSpeed() <= 0 then setGameSpeed(1) end; G.cleanLook(); G.day(); G.stand() end)
S.zoomTo(1.0)
scene("hud", function() if CWm.isOpen() then CWm.toggleBothPaired(0) end end)
scene("bare", function() UIManager.setVisibleAllUI(false) end, function() UIManager.setVisibleAllUI(true) end)
scene("pair", function() if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end end,
    function() if CWm.isOpen() then CWm.toggleBothPaired(0) end end)
S.step(10, function() Events.OnRenderTick.Remove(onFrame) end)
S.start()
