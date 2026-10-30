-- ZeDUI/tools/qa/zedqa_doll_view_on.lua  (Oct 29 2026)
-- Sets the Equip tab to its Doll view for the scripts after it (the pad map shows the doll instead of the list).
-- The run's ModOptions.ini is the runner's own copy, so the director's choice is not touched. grep "ZEDQA dvon".
local ok = pcall(function() ZeD.EquipDoll.setView("doll") end)
print("ZEDQA dvon view " .. tostring(ZeD.EquipDoll.view()) .. " ok=" .. tostring(ok))
local n = 0
local function onTick()
    n = n + 1
    if n < 5 then return end
    Events.OnTick.Remove(onTick)
    print("ZEDQA dvon DONE")   -- (after the bridge's own "run #" line, which the runner waits for)
end
Events.OnTick.Add(onTick)
