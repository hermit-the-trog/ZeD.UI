-- ZeDUI/tools/qa/gallery_v1_pitch_only.lua  (Nov 18 2026, QA): the 1.0 gallery's pitch retakes only, g1_01_zed (pitch 1)
-- and g1_26_zed (pitch 3), in Dark + PZ Teal (the director: "P1 and P3 need to show the dark theme and teal only").
-- Run before gallery_v1_a_zed.lua (gallery_v1_pitch.txt). grep "ZEDQA pto".
G1Z_ONLY = { ["26"] = true }   -- (run 2: 01 landed in run 1)
G1Z_LOOK = { "dark", "teal" }
print("ZEDQA pto beats: 26; look dark teal")
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA pto DONE") end
Events.OnTick.Add(later)
