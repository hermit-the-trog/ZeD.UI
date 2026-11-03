-- ZeDUI/tools/qa/zedqa_devices_form.lua  (Nov 2 2026, QA; punch list 60): sets ZeD setup's Devices row for the rest of
-- the run (the runner puts the director's ModOptions.ini back after). Each run flips it: Full to Simple, Simple to Full.
local S = ZeD and ZeD.Settings
if not (S and S.devicesStyleOption) then print("ZEDQA dvf ERR no Devices option"); print("ZEDQA dvf DONE"); return end
local now = S.devicesStyleOption:getValue()
local want = (now == 2) and 1 or 2
S.devicesStyleOption:setValue(want)
print("ZEDQA dvf Devices " .. tostring(now) .. " -> " .. tostring(want) .. " (simple " .. tostring(S.devicesSimple()) .. ")")
print("ZEDQA dvf DONE")
