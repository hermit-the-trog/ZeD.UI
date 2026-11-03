-- ZeDUI/tools/qa/zedqa_dash_form.lua  (Nov 2 2026, QA; punch list 60): sets ZeD setup's Dashboard row for the rest of
-- the run (the runner puts the director's ModOptions.ini back after). Each run flips it: Full to Simple, Simple to Full.
local S = ZeD and ZeD.Settings
if not (S and S.dashStyleOption) then print("ZEDQA dsf ERR no Dashboard option"); print("ZEDQA dsf DONE"); return end
local now = S.dashStyleOption:getValue()
local want = (now == 2) and 1 or 2
S.dashStyleOption:setValue(want)
print("ZEDQA dsf Dashboard " .. tostring(now) .. " -> " .. tostring(want) .. " (simple " .. tostring(S.dashSimple()) .. ")")
-- (DONE a few ticks later: the runner watches for it after the script has started)
local n = 0
local function tick() n = n + 1; if n >= 5 then Events.OnTick.Remove(tick); print("ZEDQA dsf DONE") end end
Events.OnTick.Add(tick)
