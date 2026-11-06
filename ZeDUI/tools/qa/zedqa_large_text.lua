-- ZeDUI/tools/qa/zedqa_large_text.lua  (Nov 5 2026, QA): ZeD's Large text in game, the way the option's Apply does it, for a manifest's later scripts. The runner keeps
-- and restores ModOptions.ini. grep "ZEDQA ltx".
local function say(s) print("ZEDQA ltx " .. tostring(s)) end
local opts = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI")
local o = opts and opts:getOption("textSize")
if o then
    pcall(function() o:setValue(2); if o.onChangeApply then o:onChangeApply(2) else ZeD.Settings.reapplyFromOptions() end end)
    say("text size now " .. tostring(ZeD and ZeD.currentSize))
else
    say("FAIL no textSize option")
end
local n = 0
local function later()
    n = n + 1
    if n > 60 then Events.OnTick.Remove(later); say("DONE") end
end
Events.OnTick.Add(later)
