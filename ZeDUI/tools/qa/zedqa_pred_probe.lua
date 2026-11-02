-- ZeDUI/tools/qa/zedqa_pred_probe.lua  (Nov 2 2026, QA; punch list 54, which mod breaks the game's Lua callbacks)
-- One predicate search on the character's inventory (a Java call that calls a Lua function back), at once and again
-- 120 ticks later, each inside a pcall as the QA bridge, ZeD and many mods call it. Prints PASS or FAIL with the error.
-- grep "ZEDQA pp".
local function say(s) print("ZEDQA pp " .. tostring(s)) end
local p = getPlayer()
local function probe(when)
    local ok, err = pcall(function()
        local inv = p:getInventory()
        local a = inv:containsEvalRecurse(function(it) return false end)
        local b = inv:getFirstEvalRecurse(function(it) return it:getType() == "QA_none" end)
        return tostring(a) .. "," .. tostring(b)
    end)
    say((ok and "PASS " or "FAIL ") .. when .. ": " .. tostring(err))
end
probe("start")
local n = 0
local function tick()
    n = n + 1
    if n < 120 then return end
    Events.OnTick.Remove(tick)
    probe("after 120 ticks")
    say("DONE")
end
Events.OnTick.Add(tick)
