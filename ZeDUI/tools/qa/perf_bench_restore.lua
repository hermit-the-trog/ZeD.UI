-- ZeDUI/tools/qa/perf_bench_restore.lua  (Oct 22 2026)
-- After perf_bench_zed.lua / perf_bench_van.lua: puts the frame limit, vsync and UI render
-- limit back to what the bench saved in PERF_WAS (idempotent), shows the UI again.
-- The game's own values for this machine: vsync on, not uncapped, lock 120, UI render 120.
-- "ZEDQA pbr ..." ending "ZEDQA pbr DONE".
local function say(s) print("ZEDQA pbr " .. tostring(s)) end
local w = PERF_WAS or {}
local vs, un, lk, ui = w.vsync, w.unc, w.lock, w.ui
if vs == nil then vs = true end
if un == nil then un = false end
if lk == nil then lk = 120 end
if ui == nil then ui = 120 end
pcall(function() getCore():setOptionVSync(vs) end)
pcall(function() getPerformance():setFramerateUncapped(un) end)
pcall(function() getCore():setOptionUIRenderFPS(ui) end)
local t = {}
pcall(function() t.v = getCore():getOptionVSync() end)
pcall(function() t.u = getPerformance():isFramerateUncapped() end)
pcall(function() t.l = getPerformance():getFramerate() end)
pcall(function() t.i = getCore():getOptionUIRenderFPS() end)
say(string.format("limits: vsync=%s uncapped=%s lock=%s uiRender=%s", tostring(t.v), tostring(t.u), tostring(t.l), tostring(t.i)))
pcall(function() UIManager.setVisibleAllUI(true) end)
-- (DONE a few frames later: the runner counts a script's lines only after the bridge has said it ran it;
-- said at once, the run timed out here; Oct 22 2026)
local waitN = 0
local function later()
    waitN = waitN + 1
    if waitN < 30 then return end
    Events.OnRenderTick.Remove(later)
    say("DONE")
end
Events.OnRenderTick.Add(later)
