-- ZeDUI/tools/qa/zedqa_scale2.lua  (Oct 31 2026, QA): UI scale 2.0 for the rest of the run (ZeD.Scale.override; the run
-- ends with the game closing, so nothing to put back). grep "ZEDQA sc2".
-- STRESS PROBE ONLY (punch list 39): ZeD setup caps the UI scale at what fits the screen (0.75 at 1280x720 and
-- 1280x800), so a run of this at the small screens is a stress probe, not a layout check. The override is not capped.
ZeD.Scale.override = 2.0; ZeD.Scale.refresh(); ZeD.applyTheme()
local n = 0
local function f() n = n + 1; if n == 30 then pcall(ZeD_Window.resetLayout) end; if n < 60 then return end; Events.OnTick.Remove(f); print("ZEDQA sc2 root " .. tostring(ZeD.Scale.root and ZeD.Scale.root())); print("ZEDQA sc2 DONE") end
Events.OnTick.Add(f)
