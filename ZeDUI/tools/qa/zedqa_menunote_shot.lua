-- ZeDUI/tools/qa/zedqa_menunote_shot.lua  (Nov 8 2026, QA): AT THE MAIN MENU. A picture of the desk with the
-- corkboard's change note (ZeD.MenuNote), for the director to check the handwriting fits. grep "ZEDQA mmn".
-- Run: pwsh -File zedqa_menu_mods_run.ps1 -ModList <empty file> -Script <this> -Tag mmn -TimeoutSec 120
local tick = 0
local function say(s) print("ZEDQA mmn " .. tostring(s)) end
local function onFE()
    tick = tick + 1
    if tick == 120 then
        say("note lines: " .. table.concat(ZeD.MenuNote or {}, " / "))
        pcall(function() getCore():TakeFullScreenshot("zqa_mmn_note.png") end)
    elseif tick == 160 then
        say("DONE")
        Events.OnFETick.Remove(onFE)
    end
end
Events.OnFETick.Add(onFE)
