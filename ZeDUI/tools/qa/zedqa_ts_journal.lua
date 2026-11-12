-- ZeDUI/tools/qa/zedqa_ts_journal.lua  (Nov 11 2026, QA): a Bound Journal into the inventory for zedqa_tab_search.lua's step 4 (tag tsj1); tag tsj2 (run again) takes it out.
TSJ_N = (TSJ_N or 0) + 1
local p = getPlayer()
local tag = "tsj" .. TSJ_N
local function say(s) print("ZEDQA " .. tag .. " " .. s) end
if TSJ_N == 1 then
    TSJ_ITEM = p:getInventory():AddItem("Base.SkillRecoveryBoundJournal")
    say("a Bound Journal given: " .. tostring(TSJ_ITEM ~= nil))
else
    if TSJ_ITEM then pcall(function() local c = TSJ_ITEM:getContainer(); if c then c:Remove(TSJ_ITEM) end end) end
    TSJ_ITEM = nil
    say("the Bound Journal taken out again")
end
local n = 0
local function later() n = n + 1; if n > 20 then Events.OnTick.Remove(later); say("DONE") end end
Events.OnTick.Add(later)
