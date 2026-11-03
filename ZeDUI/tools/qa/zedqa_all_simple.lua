-- ZeDUI/tools/qa/zedqa_all_simple.lua  (Nov 2 2026, QA; the beta checklist, part C): every Full or simple row on Simple
-- for the rest of the run (the runner puts the director's ModOptions.ini back after): Belt, Action bar, Context menu
-- (the list), Equip view (the list), Devices, Watch, Dashboard. grep "ZEDQA asp".
local S = ZeD and ZeD.Settings
local rows = { { "beltStyleOption", 2 }, { "actionBarOption", 2 }, { "contextStyleOption", 2 }, { "equipViewOption", 1 },
    { "devicesStyleOption", 2 }, { "watchStyleOption", 2 }, { "dashStyleOption", 2 } }
for _, r in ipairs(rows) do
    local o = S and S[r[1]]
    if o then o:setValue(r[2]); print("ZEDQA asp " .. r[1] .. " = " .. tostring(o:getValue()))
    else print("ZEDQA asp ERR no " .. r[1]) end
end
local k = 0
local function tick() k = k + 1; if k >= 5 then Events.OnTick.Remove(tick); print("ZEDQA asp DONE") end end
Events.OnTick.Add(tick)
