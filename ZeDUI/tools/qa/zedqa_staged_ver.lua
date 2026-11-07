-- ZeDUI/tools/qa/zedqa_staged_ver.lua  (Nov 6 2026, QA): which copy of ZeD is loaded: its version and folder, read from the game. grep "ZEDQA sv".
local mi = getModInfoByID("ZeD_UI")
print("ZEDQA sv version=" .. tostring(mi and mi:getModVersion()) .. " dir=" .. tostring(mi and mi:getDir()))
local n = 0
local function t() n = n + 1; if n == 20 then Events.OnTick.Remove(t); print("ZEDQA sv DONE") end end
Events.OnTick.Add(t)
