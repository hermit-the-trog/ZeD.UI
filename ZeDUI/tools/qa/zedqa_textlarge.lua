-- ZeDUI/tools/qa/zedqa_textlarge.lua  (Oct 31 2026, QA): Large text for the rest of the run (the game closes after it). grep "ZEDQA txl".
ZeD.applyTheme(ZeD.currentBase, ZeD.currentAccent, "large")
local n = 0
local function f() n = n + 1; if n == 20 then pcall(ZeD_Window.resetLayout) end; if n < 40 then return end; Events.OnTick.Remove(f); print("ZEDQA txl size " .. tostring(ZeD.currentSize)); print("ZEDQA txl DONE") end
Events.OnTick.Add(f)
