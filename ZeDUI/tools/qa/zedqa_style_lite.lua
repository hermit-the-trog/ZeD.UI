-- ZeDUI/tools/qa/zedqa_style_lite.lua  (Nov 20 2026, QA; tag stl): Style = Lite for the rest of the run (the value
-- only; the option's onChange would also set the additions to Vanilla). The runner puts ModOptions.ini back after.
-- For measuring and deep runs in Lite: perf_lite.txt. grep "ZEDQA stl".
local o = ZeD and ZeD.Settings and ZeD.Settings.lookStyleOption
local ok = o ~= nil and pcall(function() o:setValue(2) end)
print("ZEDQA stl Style Lite set " .. tostring(ok) .. ", lite() " .. tostring(ZeD.Settings.lite and ZeD.Settings.lite()))
local n = 0
local function later() n = n + 1; if n < 30 then return end; Events.OnTick.Remove(later); print("ZEDQA stl DONE") end
Events.OnTick.Add(later)
